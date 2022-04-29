terraform {

  backend "remote" {
    organization = "apostoli"
    workspaces {
      name = "k8sbacup-minio"
    }
  }

}

data "sops_file" "minio_secrets" {
  source_file = "secret.sops.yaml"
}

module "k8sbackup-bucket" {
  source = "../module"

  name    = "k8s-backup"
  secrets = data.sops_file.minio_secrets.data
}