# Backup and Restores

## Service Backups
Backups are handled by velero. They run nightly and will backup any pods and pvcs attached to pods that are annotated properly. Be sure to properly labeel the resources for the app so they can be selectively restored. See below example:

```
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kubia
  template:
    metadata:
      name: kubia
      labels:
        app: kubia
      annotations:
        backup.velero.io/backup-volumes: custom 
```
This value on the annotation should be the name of the volume you wish to backup.

## Service Restores
Restores must be done for the pod and the volume at the same time. Best option is to pause the flux syncing for the resource, delete the resources associated with the app and then initiate a restore with the below command
```
velero restore create --from-backup velero-daily-backup-20211013060052 --restore-volumes=true --include-namespaces default -l app=kubia
```
Specify the namespace the app is located in, and the label selectors on the application and volume. If the resources are not properly labeled in the backup, then restore the entire namespace.

## Manual Data Manipulation

Taken from [Onedr0p's guide](https://onedr0p.github.io/home-cluster/storage/rook-pvc-backup/).

## Create the toolbox container

!!! info "Ran from your workstation"

```sh
kubectl -n rook-ceph exec -it $(kubectl -n rook-ceph get pod -l "app=rook-direct-mount" -o jsonpath='{.items[0].metadata.name}') -- bash
```

!!! info "Ran from the `rook-ceph-toolbox`"

```sh
mkdir -p /mnt/data
```

## Move data to a NFS share or vice versa

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

Following the same pattern from [Service Restores](./BACKUPS.md#service-restores), create a velero restore job

```sh
vagrant@control:/code/k8s-gitops$ velero get backups
NAME                                 STATUS            ERRORS   WARNINGS   CREATED                         EXPIRES   STORAGE LOCATION   SELECTOR
velero-daily-backup-20211119060033   Completed         0        0          2021-11-19 11:00:33 +0000 UTC   4d        default            <none>
velero-daily-backup-20211118082401   Completed         0        0          2021-11-18 13:24:01 +0000 UTC   3d        default            <none>
velero-daily-backup-20211118081532   PartiallyFailed   2        0          2021-11-18 13:15:33 +0000 UTC   3d        default            <none>
velero-daily-backup-20211117060027   Completed         0        0          2021-11-17 11:00:27 +0000 UTC   32d       default            <none>
velero-daily-backup-20211116060025   Completed         0        0          2021-11-16 11:00:25 +0000 UTC   1d        default            <none>
velero-daily-backup-20211115060024   Completed         0        0          2021-11-15 11:00:24 +0000 UTC   20h       default            <none>

vagrant@control:/code/k8s-gitops$ velero restore create --from-backup velero-daily-backup-20211117060027 --restore-volumes=true --include-namespaces media
Restore request "velero-daily-backup-20211117060027-20211119144002" submitted successfully.
Run `velero restore describe velero-daily-backup-20211117060027-20211119144002` or `velero restore logs velero-daily-backup-20211117060027-20211119144002` for more details.
vagrant@control:/code/k8s-gitops$ velero get restores
NAME                                                BACKUP                               STATUS       STARTED                         COMPLETED   ERRORS   WARNINGS   CREATED                         SELECTOR
velero-daily-backup-20211117060027-20211119144002   velero-daily-backup-20211117060027   InProgress   2021-11-19 14:40:01 +0000 UTC   <nil>       0        0          2021-11-19 14:40:01 +0000 UTC   <none>
vagrant@control:/code/k8s-gitops$
```
Wait for restore to complete, once completed, scale services back to desired number of replicas.

Resume flux syncing
```
flux resume hr plex -n media
```