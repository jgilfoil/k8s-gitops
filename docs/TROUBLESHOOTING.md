# Troubleshooting

## K3s

### k3s log location
```
less /var/log/k3s.log
less /var/log/syslog
journalctl -u k3s
```
### Embedded etcd3

See etcd tool and commands [here](https://gist.github.com/superseb/0c06164eef5a097c66e810fe91a9d408)

## Flux

Find logs if flux deployment is failing. Examples:
```
flux logs --kind=helmrelease --level=error -n rook-ceph
flux logs --kind=kustomization --level=info -n flux-system
```

## Velero

Edit Velero Backup Retention. Example:
```
vagrant@control:/code/k8s-gitops$ velero get backups
NAME                                 STATUS            ERRORS   WARNINGS   CREATED                         EXPIRES   STORAGE LOCATION   SELECTOR
velero-daily-backup-20211119060033   Completed         0        0          2021-11-19 11:00:33 +0000 UTC   4d        default            <none>  
velero-daily-backup-20211118082401   Completed         0        0          2021-11-18 13:24:01 +0000 UTC   3d        default            <none>  
velero-daily-backup-20211118081532   PartiallyFailed   2        0          2021-11-18 13:15:33 +0000 UTC   3d        default            <none>
velero-daily-backup-20211117060027   Completed         0        0          2021-11-17 11:00:27 +0000 UTC   32d       default            <none>
velero-daily-backup-20211116060025   Completed         0        0          2021-11-16 11:00:25 +0000 UTC   1d        default            <none>
velero-daily-backup-20211115060024   Completed         0        0          2021-11-15 11:00:24 +0000 UTC   20h       default            <none>

vagrant@control:/code/k8s-gitops$ kubectl -n velero edit backup velero-daily-backup-20211117060027
```
Modify the status.expiration line and save.