# K8s-Gitops Cluster Setup

This covers the initial setup of this cluster and how it was created should it ever need to be re-created.

## Media

### NFS Setup
NFS must be enabled on the media share and permissions under `Control Panel` > `Shared Folders` > `NFS Permissions` must be created to allow each k8s node to access the nfs share.

Settings for each rule should be:
```
Privledge: read/write
Squash: Map all users to admin
Security: sys
Enable asynchronous: true
Allow connections from non-privledged ports: true
Allow users to access mounted subfolders: true
```

### Plex
When a new Plex server is deployed, the following must be done:

First you must login to the instance directly, not through the ingress address. Run the following command from git-bash on the local windows workstation to expose the pod to your local system.
```
kubectl --kubeconfig ./kubeconfig -n media port-forward `kubectl --kubeconfig ./kubeconfig -n media get po -l app.kubernetes.io/name=plex --no-headers -o custom-columns=":metadata.name"` 32400:32400
```
Open (https://localhost:32400/web) in your local browser. Claim the server via your plex login and then go to `Settings` > Make sure the new plex server is selected > `Settings` > `Network`

Set the following Settings:

Lan Networks
```
192.168.1.0/24,10.42.1.0/24,10.43.0.0/16
```

Check `Treat WAN IP As LAN Bandwidth`

Uncheck `Enable Relay`

Custom server access URLs
```
https://192.168.1.210,https://plexhostname.${Your.Domain}
```
