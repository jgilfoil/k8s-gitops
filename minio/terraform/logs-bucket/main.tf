terraform {

  backend "remote" {
    organization = "apostoli"
    workspaces {
      name = "logs-minio"
    }
  }

}

data "sops_file" "minio_secrets" {
  source_file = "secret.sops.yaml"
}

module "logs-bucket" {
  source = "../module"

  name    = "loki"
  secrets = data.sops_file.minio_secrets.data
}
