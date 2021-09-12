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
5. Deploy the container. The Container deployment settings are backed up in the Backup Volume:cluster/NAS/minio/cluster-backup.syno.json. Settings used were:
  - volume mount /cluster-backup/config:/root/.minio
  - volume mount /cluster-backup/data:/data
  - port 9000:9000
  - port 9001:9001
  - command: minio server /data --console-address :9001
  - env var: MINIO_ROOT_USER: <minio username in safe>
  - env var: MINIO_ROOT_PASSWORD: <minio password in safe>
 6. configure the user, policy and bucket from the control vm:

```
mc alias set minio http://wanshitong.apostoli.pw:9000 <MINIO_ROOT_USER> "<MINIO_ROOT_PASSWORD>"
mc admin user add minio/ <K8s Backups Access Key> <Secret Key>
mc admin policy add minio/ k8sbackupreadwrite ./minio/k8s-backups-read-write.json
mc admin policy set minio k8sbackupreadwrite user=<K8s Backups Access Key>
mc alias set minio-k8sbackup http://wanshitong.apostoli.pw:9000 <K8s Backups Access Key> <Secret Key>
mc mb minio-k8sbackup/k8sbackups
```

## Restore Procedures
In the event that the Minio container is no longer operational or is corrupted somehow, as long as you have a copy of the data and the configs from the cluster-block-backups volume on the NAS, you can follow these restore procedures.


```

```