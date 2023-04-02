terraform {

  required_providers {
    minio = {
      source = "aminueza/minio"
      version = "1.13.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = ">= 0.7.0"
    }
  }
}