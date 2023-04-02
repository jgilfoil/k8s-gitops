terraform {
  backend "s3" {
    bucket  = "k8s-gitops-tf-state-bucket20230115030133278000000001"
    key     = "k8s-minio-backup/terraform.tfstate"
    region  = "us-east-2"
    encrypt = true
    dynamodb_table = "terraform-state-lock"
  }
}


data "sops_file" "minio_secrets" {
  source_file = "secret.sops.yaml"
}

module "minio-bucket" {
  source = "../module/aminueza"

  name    = "volsync"
  secrets = data.sops_file.minio_secrets.data
}

output "minio-user-key" {
  value     = module.minio-bucket.secret
  sensitive = true
}