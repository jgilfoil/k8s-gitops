terraform {

  required_providers {
    minio = {
      source = "aminueza/minio"
      version = "1.15.2"
    }
    sops = {
      source  = "carlpett/sops"
      version = ">= 0.7.0"
    }
  }
}