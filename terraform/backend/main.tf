provider "aws" {
    region = "us-east-2"
}

resource "aws_s3_bucket" "backend" {
  bucket_prefix = "k8s-gitops-tf-state-bucket"
}

resource "aws_s3_bucket_acl" "backend" {
  bucket = aws_s3_bucket.backend.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "backend" {
  bucket = aws_s3_bucket.backend.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "backend_lock" {
  name           = "terraform-state-lock"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

terraform {
  backend "s3" {
    bucket  = "k8s-gitops-tf-state-bucket20230115030133278000000001"
    key     = "terraform.tfstate"
    region  = "us-east-2"
    encrypt = true
    dynamodb_table = "terraform-state-lock"
  }
}
