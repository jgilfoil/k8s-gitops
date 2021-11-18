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

## Cluster Restores

(if you are wiping the entire cluster, probably best to investigate pausing ceph replication to avoid hanging processes as we take nodes down)

Uninstall k3s

For server nodes:
```sh
sudo /usr/local/bin/k3s-uninstall.sh
```

Fore agent nodes:
```sh
sudo /usr/local/bin/k3s-agent-uninstall.sh
```

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
