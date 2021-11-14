# Backup and Restores

## Backups
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

## Restores
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
mkdir -p /mnt/nfsdata
mkdir -p /mnt/data
mount -t nfs -o "nfsvers=4.1,hard" 192.168.42.60:/Data /mnt/nfsdata
```

## Move data to a NFS share or vice versa

!!! info "Ran from your workstation"

- Pause the Flux Helm Release

```sh
flux suspend hr home-assistant -n home
```

- Scale the application down to zero pods

```sh
kubectl scale deploy/home-assistant --replicas 0 -n home
```

- Get the `csi-vol-*` string

```sh
kubectl get pv/(kubectl get pv | grep home-assistant-config-v1 | awk -F' ' '{print $1}') -n home -o json | jq -r '.spec.csi.volumeAttributes.imageName'
```

!!! info "Ran from the `rook-ceph-toolbox`"

```sh
rbd map -p replicapool csi-vol-ebb786c7-9a6f-11eb-ae97-9a71104156fa \
    | xargs -I{} mount {} /mnt/data
tar czvf /mnt/nfsdata/Backups/home-assistant.tar.gz -C /mnt/data/ .
umount /mnt/data
rbd unmap -p replicapool csi-vol-ebb786c7-9a6f-11eb-ae97-9a71104156fa
```
