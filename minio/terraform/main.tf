terraform {

  backend "remote" {
    organization = "apostoli"
    workspaces {
      name = "minio"
    }
  }

  required_providers {
    minio = {
      source  = "refaktory/minio"
      version = "0.1.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "0.6.3"
    }
  }
}

data "sops_file" "minio_secrets" {
  source_file = "secret.sops.yaml"
}

provider "minio" {
  endpoint   = data.sops_file.minio_secrets.data["minio_endpoint"]
  access_key = data.sops_file.minio_secrets.data["minio_root_user"]
  secret_key = data.sops_file.minio_secrets.data["minio_root_password"]
  ssl        = false
}

locals {
  bucket_settings = {
    "loki"     = { versioning_enabled = false }
    #"k8sbackup"   = { versioning_enabled = false } # Disabling this for now 
                                                    # since I don't want to 
                                                    # mess with importing it 
                                                    # and have tf recreate the 
                                                    # bucket haphzardly.
  }
}

resource "minio_bucket" "map" {
  for_each = local.bucket_settings

  name               = each.key
  versioning_enabled = each.value.versioning_enabled
}

########## LOKI Bucket Configuration ################
#
resource "minio_canned_policy" "loki_read_write" {
  name = "loki_read_write"
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
                "arn:aws:s3:::loki",
                "arn:aws:s3:::loki/*"
            ]
        }
    ]
}
EOT
}


resource "minio_user" "loki" {
  access_key = data.sops_file.minio_secrets.data["minio_user_loki_access_key"]
  secret_key = data.sops_file.minio_secrets.data["minio_user_loki_secret_key"]
  policies = [
    minio_canned_policy.loki_read_write.name
  ]
}

#
########## End of LOKI Bucket Configuration ##########

########## Velero Bucket Configuration ################
#

#* The provider here has some kind of bug that causes the policies to be replaced with every apply
#  Doesn't seem to be hurting anything as it's just policies and users, just makes sure the policy
#  is attached to the user when you're done.
resource "minio_canned_policy" "velero_read_write" {
  name = "k8sbackupreadwrite"
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
                "arn:aws:s3:::k8sbackups",
                "arn:aws:s3:::k8sbackups/*"
            ]
        }
    ]
}
EOT
}

resource "minio_user" "velero" {
  access_key = data.sops_file.minio_secrets.data["minio_user_velero_access_key"]
  secret_key = data.sops_file.minio_secrets.data["minio_user_velero_secret_key"]
  policies = [
    minio_canned_policy.velero_read_write.name
  ]
}

#
########## End of Velero Bucket Configuration ##########
