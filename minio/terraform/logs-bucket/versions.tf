terraform {

  required_providers {
    minio = {
      source  = "refaktory/minio"
      version = "0.1.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "0.7.2"
    }
  }
}
