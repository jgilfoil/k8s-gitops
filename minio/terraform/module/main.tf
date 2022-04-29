provider "minio" {
  endpoint   = var.secrets["minio_endpoint"]
  access_key = var.secrets["minio_root_user"]
  secret_key = var.secrets["minio_root_password"]
  ssl        = false
}

resource "minio_bucket" "map" {
  name               = var.name
  versioning_enabled = var.versioning
}


resource "minio_canned_policy" "read_write" {
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


resource "minio_user" "this" {
  access_key = var.secrets["minio_user_access_key"]
  secret_key = var.secrets["minio_user_secret_key"]
  policies = [
    minio_canned_policy.read_write.name
  ]
}