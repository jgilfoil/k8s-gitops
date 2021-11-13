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