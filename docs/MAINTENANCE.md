# Maintenance Resources

This doc covers some miscelanous things that are handy to have around.

## Moving existing CRD's into Helm Management

Originally Rook-ceph and Cert-manager CRDs were managed in their own kustomization in the CRD folder. Helm can now manage these CRDs, so in order to do so without deleting the existing crds, you need to annotate them so helm recongizes them before removing them from the CRDs kustomization. The following is an example when doing this for rook-ceph. (Hattip to allenporter for the commands to annotate all the crds)
```
flux suspend -n rook-ceph hr rook-ceph
flux suspend -n rook-ceph hr rook-ceph-cluster
merge commit with install crds values
flux suspend ks crds
kubectl get crd | egrep 'rook.io|objectbucket' | cut -f 1 -d ' ' > ./temp/crds
cat ./temp/crds | xargs -i kubectl annotate crd {} app.kubernetes.io/managed-by=Helm meta.helm.sh/release-name=rook-ceph meta.helm.sh/release-namespace=rook-ceph
cat ./temp/crds | xargs -i kubectl label crd {} app.kubernetes.io/managed-by=Helm  
flux resume hr rook-ceph -n rook-ceph
flux resume hr rook-ceph-cluster -n rook-ceph
merge commit with removed crds directory
flux resume ks crds
```

abbreviated example for cert-manager
```
kubectl get crd | egrep 'cert-manager.io' | cut -f 1 -d ' ' > ./temp/crds-certmanager
cat ./temp/crds-certmanager | xargs -i kubectl annotate crd {} app.kubernetes.io/managed-by=Helm meta.helm.sh/release-name=cert-manager meta.helm.sh/release-namespace=cert-manager
cat ./temp/crds-certmanager | xargs -i kubectl label crd {} app.kubernetes.io/managed-by=Helm  
```