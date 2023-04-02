provider "minio" {
  minio_server   = var.secrets["minio_endpoint"]
  minio_user     = var.secrets["minio_root_user"]
  minio_password = var.secrets["minio_root_password"]
  minio_insecure = true
}

resource "minio_s3_bucket" "this" {
  bucket = var.name
  acl    = "private"
}

resource "minio_s3_bucket_versioning" "bucket" {
  bucket = minio_s3_bucket.this.bucket

  versioning_configuration {
    status = var.versioning
  }
}

resource "minio_iam_policy" "read_write" {
  name   = "${var.name}_read_write"
  policy = <<EOT
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:*"
            ],
            "Resource": [
                "arn:aws:s3:::${var.name}",
                "arn:aws:s3:::${var.name}/*"
            ]
        }
    ]
}
EOT
}


resource "minio_iam_user" "this" {
  name     = var.name
}

resource "minio_iam_user_policy_attachment" "this" {
  user_name      = "${minio_iam_user.this.id}"
  policy_name = "${minio_iam_policy.read_write.id}"
}

output "secret" {
  value = "${minio_iam_user.this.secret}"
}