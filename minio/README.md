# Minio Setup
I've deployed Minio on my Synology NAS in a container to act as my s3 target for my backup system in k8s. 

## Deploying Minio

I loosely followed these setup steps.
<details>
Most of the installation setup instructions came from these links:

https://jonaharagon.me/installing-minio-on-synology-diskstation-4823caf600c3

https://hub.docker.com/r/minio/minio/
</details>

1. Install Docker Package on Synology
2. Setup a Volume to backend Minio
3. Setup a File share using that Volume
4. Download the Minio Container minio/minio:latest
5. Deploy container with Ansible
```
cd ansible/
ansible-playbook site.yml
```
6. Configure minio buckets with Terraform. The backend is stored in terraform cloud, so you must do terraform login prior to running apply.
```
cd terraform/logs-bucket
terraform init && terraform apply
cd ../k8sbackup-bucket
terraform init && terraform apply
```

## Restore Procedures
In the event that the Minio container is no longer operational or is corrupted somehow, as long as you have a copy of the data and the configs from the cluster-block-backups volume on the NAS, you can follow these restore procedures. Logs volume can just be created, no need to back up that data.

```
Restore minio container and config (ansible/config)
copy data over from backup
profit??
this is untested as of yet
```

## Backend
If you're using terraform enterprise to store state, Create a workspace and set the `Execution Mode` to local, else it will try to execute your cli commands from terraform's servers and fail to decrypt or connect to your local minio instance.

## Encryption

Example encrypting MINIO_LOGS_ROOT_USER in roles/minio/vars/main.yml:
```
ansible-vault encrypt_string 'user_name' --name 'MINIO_LOGS_ROOT_USER'
```
Check encrypted variable in host_vars/synology:
```
ansible localhost -m debug -a var="my_remote_user" -e "@host_vars/synology"
```