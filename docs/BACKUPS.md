# Backup and Restores

## Data Backups
Backups are handled by volsync. They run nightly for any replicationsource objects in place. See below example:

```
---
apiVersion: volsync.backube/v1alpha1
kind: ReplicationSource
metadata:
  name: prowlarr
  namespace: media
spec:
  sourcePVC: prowlarr-config-v1
  trigger:
    schedule: "00 11 * * *"
  restic:
    copyMethod: Snapshot
    pruneIntervalDays: 10
    repository: prowlarr-restic-secret
    cacheCapacity: 2Gi
    volumeSnapshotClassName: csi-ceph-blockpool
    storageClassName: ceph-block
    retain:
      daily: 10
      within: 3d
```
The above will snapshot the target pvc once per day, and then copy the contents via restic to a local minio service, which is back-ended by an nfs share from the NAS.
## Data Restores
Restores are triggered by applying a ReplicationDesination manifest for the target pvc. You must prepare the target deployment/pvc before initiating a restore.

### Check current backup list

You can use this job to get a list of the backups via restic
```
---
apiVersion: batch/v1
kind: Job
metadata:
  name: "list-prowlarr-20230116-0959"
  namespace: "media"
spec:
  ttlSecondsAfterFinished: 3600
  template:
    spec:
      automountServiceAccountToken: false
      restartPolicy: OnFailure
      containers:
        - name: list
          image: docker.io/restic/restic:0.14.0
          args: ["snapshots"]
          envFrom:
            - secretRef:
                name: "prowlarr-restic-secret"
```
Update the secret name for the target pvc appropriately, referenced from the ReplicationSource used originally.

### Prepare Target Deployment/PVC
Suspend the Flux Helm Release for the deployment that uses the target PVC.
```
flux -n media suspend hr prowlarr
```
Scale down the target deployment
```
kubectl scale deploy/prowlarr --replicas 0 -n media
```
Wipe the PVC if neccessary
The restore process will only overwrite existing files, it does not remove any files that don't exist in the backup. It's probably best to wipe it unless you're very very sure. Deploy the following pod to access the PVC.
```
---
apiVersion: v1
kind: Pod
metadata:
  name: temp-shell
  namespace: media
spec:
  containers:
    - name: temp-shell
      image: busybox
      command: ["tail", "-f", "/dev/null"]
      volumeMounts:
      - name: config
        mountPath: /config
  volumes:
  - name: config
    persistentVolumeClaim:
      claimName: prowlarr-config-v1
```
Exec into the container and remove all data from the target volume.
```
kubectl -n media exec -it temp-shell -- /bin/sh -c 'rm -rf /config/*'
```
Delete the pod when done

### Restore Data to PVC
Apply the replicationdestination.yaml found in the backups/ folder of the target service. Example:

```
---
apiVersion: volsync.backube/v1alpha1
kind: ReplicationDestination
metadata:
  name: "prowlarr-2023-01-17-2110"
  namespace: "media"
spec:
  trigger:
    manual: restore-once
  restic:
    repository: "prowlarr-restic-secret"
    destinationPVC: "prowlarr-config-v1"
    copyMethod: Direct
    storageClassName: ceph-block
    # IMPORTANT NOTE:
    #   Set to the last X number of snapshots to restore from
    previous: 1
    # OR;
    # IMPORTANT NOTE:
    #   On bootstrap set `restoreAsOf` to the time the old cluster was destroyed.
    #   This will essentially prevent volsync from trying to restore a backup
    #   from a application that started with default data in the PVC.
    #   Do not restore snapshots made after the following RFC3339 Timestamp.
    #   date --rfc-3339=seconds (--utc)
    # restoreAsOf: "2022-12-10T16:00:00-05:00"
```
Check on it's progress with 
```
k -n media get replicationdestination
```
Once completed verify the files are restored by creating the temp-shell pod again, and then scale the deployment back to the original size.
```
kubectl scale deploy/prowlarr --replicas 1 -n media
```
Resume the Flux HelmRelease once the app is confirmed working.
```
flux -n media resume hr prolwarr
```
## Manual Data Manipulation

### VolSync Restic CLI

Use [restic-cli.yaml](../tests/volsync/restic-cli.yaml) to get a pod you can shell into and execute restic commands from.

This is particularly useful when troubleshooting a locked backend like this:
```
Fatal: unable to create lock in backend: repository is already locked by PID 33 on volsync-src-plex-s84f5 by  (UID 0, GID 0) 
lock was created at 2023-07-26 23:44:23 (186h12m34.666809971s ago)
```

then 
```
restic unlock
```


Taken from [Onedr0p's guide](https://onedr0p.github.io/home-cluster/storage/rook-pvc-backup/).

### Create the toolbox container

!!! info "Ran from your workstation"

```sh
kubectl -n rook-ceph exec -it $(kubectl -n rook-ceph get pod -l "app=rook-direct-mount" -o jsonpath='{.items[0].metadata.name}') -- bash
```

!!! info "Ran from the `rook-ceph-toolbox`"

```sh
mkdir -p /mnt/data
```

### Move data to a NFS share or vice versa

!!! info "Ran from your workstation"

- Pause the Flux Helm Release

```sh
flux suspend hr plex -n media
```

- Scale the application down to zero pods

```sh
kubectl scale deploy/plex --replicas 0 -n media
```

- Get the `csi-vol-*` string

```sh
kubectl get pv/$(kubectl get pv | grep plex-config-v1 | awk -F' ' '{print $1}') -n home -o json | jq -r '.spec.csi.volumeAttributes.imageName'
```

!!! info "Ran from the `rook-ceph-toolbox`"

```sh
rbd map -p ceph-blockpool csi-vol-f9b9f8e5-430f-11ec-8e89-f6070945344b \
    | xargs -I{} mount {} /mnt/data
tar czvf /mnt/nfsdata/Backups/home-assistant.tar.gz -C /mnt/data/ .
umount /mnt/data
rbd unmap -p ceph-blockpool csi-vol-f9b9f8e5-430f-11ec-8e89-f6070945344b
```

## Cluster Rebuild/Restore

(if you are wiping the entire cluster, probably best to investigate pausing ceph replication to avoid hanging processes as we take nodes down)

### Uninstall k3s

For server nodes:
```sh
sudo /usr/local/bin/k3s-uninstall.sh
```

Fore agent nodes:
```sh
sudo /usr/local/bin/k3s-agent-uninstall.sh
```

### Prepare Ceph Disks
Wipe ceph ssd disks. See [Rook Documentation](https://github.com/rook/rook/blob/v1.7.7/Documentation/ceph-teardown.md#zapping-devices) for source instructions
```sh
DISK="/dev/sda"
sudo sgdisk --zap-all $DISK
sudo blkdiscard $DISK
ls /dev/mapper/ceph-* | sudo xargs -I% -- dmsetup remove %
sudo rm -rf /dev/ceph-*
sudo rm -rf /dev/mapper/ceph--*
sudo partprobe $DISK
```

### Reinstall OS
Use ubuntu 20.04 LTS [installer](https://ubuntu.com/tutorials/create-a-usb-stick-on-windows#1-overview) on USB Stick to boot and install OS. Follow Instructions from [here](https://github.com/jgilfoil/cluster-infra#deploying-os-on-nodes) for os install and [here](https://github.com/jgilfoil/cluster-infra#node-configuration) for node preperation.

### Install K3s 

Install k3 [instructions](./SETUP.md#sailboat-installing-k3s-with-k3sup)

### Deploy Flux

Make sure you have your [gpg keys](./SETUP.md#closed_lock_with_key-setting-up-gnupg-keys) setup on your control environment

Follow steps 1, 2, 3 and 10 from [here](SETUP.md#small_blue_diamond-gitops-with-flux)

It will take some time for all the pieces to deploy. Check `kubectl get pods --all-namespaces -w` to watch deployments and https://homer.${SECRET_DOMAIN} to check things are working. This will not deploy data, see next section for data/pvc restores.

### PVC Restores

At this point, velero should be deployed and it should have recognized the backups from minio on the NAS. We're going to restore one namespace at a time.

First Suspend the helm release or deployment of each service in the target namespace. In this example we'll use namespace `media` and service `plex`.

```sh
flux suspend hr plex -n media
```

Delete all resources associated with the app. For now we're gonna try this with deleting the entire namespace. Perhaps we can do this with labels going forward instead.
```sh
kubectl delete ns media
```

Following the same pattern from [Data Restores](./BACKUPS.md#data-restores). Follow those steps for each app. Best to start with plex and work your way backwards into the rest of applications in the chain, transmission, radarr, etc.

## NAS Backups

This is just to document what i'm doing with all my different NAS Volumes with respect to backups in the event that the NAS needs to be restored.

 * Synology Configuration file (.dss) is currently manually exported periodically and uploaded to Google Drive\Backups
 * Minio docker config is backed up to to `Backup` Volume on NAS. See [here](https://github.com/jgilfoil/k8s-gitops/blob/main/minio/README.md#deploying-minio) for more details
 * Volume `Backup` is replicated to RAID Array on Forge and external usb storage
 * Volume `cluster-backup` is sync'd to Google Drive\Backups via Synology Cloud Sync, in addition to local RAID Array on Forge
 * Volume `minio` is sync'd to Google Drive\Backups via Synology Cloud Sync, in addition to local RAID Array on Forge
 * Volume `docker` is not backed up. I think this is used to store container images.
 * Volume `Documents` is synce'd to Google Drive\Backups via Synology Cloud Sync, in addition to local RAID Array on Forge
 * Volume `Logs` is not backed up. This is just reports from Synology on the system.
 * Volume `Software` is replicated to RAID Array on Forge and external usb storage
 * Volume `vm-backups` is replicated to RAID Array on Forge and external usb storage

I Believe a restore procedure would look something like this:

 * Import .dss config file from Google Drive\Backups
 * Restore data to volumes from their various backup sources
 * Do a cloud Sync Restore from google drive to `cluster-backup`, `minio` and `Documents` volumes
 * Restore minio docker instance from the configuration bacup json file
