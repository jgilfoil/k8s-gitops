# Jason's K3s Cluster state managed by Flux

[GitOps](https://www.weave.works/blog/what-is-gitops-really) Repo for deploying my [k3s](https://k3s.io/) cluster with [k3sup](https://github.com/alexellis/k3sup) backed by [Flux](https://toolkit.fluxcd.io/) and [SOPS](https://toolkit.fluxcd.io/guides/mozilla-sops/).

## Overview

- [Introduction](https://github.com/jgilfoil/k8s-gitops#wave-introduction)
- [Prerequisites](https://github.com/jgilfoil/k8s-gitops#memo-prerequisites)
- [Repository structure](https://github.com/jgilfoil/k8s-gitopss#open_file_folder-repository-structure)
- [Lets go!](https://github.com/jgilfoil/k8s-gitops#rocket-lets-go)
- [Post installation](https://github.com/jgilfoil/k8s-gitops#mega-post-installation)
- [Thanks](https://github.com/k8s-at-home/jgilfoil/k8s-gitops#handshake-thanks)

## :wave:&nbsp; Introduction

The following components are installed in this [k3s](https://k3s.io/) cluster.

- [flannel](https://github.com/flannel-io/flannel)
- [local-path-provisioner](https://github.com/rancher/local-path-provisioner)
- [flux](https://toolkit.fluxcd.io/)
- [metallb](https://metallb.universe.tf/)
- [cert-manager](https://cert-manager.io/) with Google CloudDNS DNS challenge
- [traefik](https://traefik.io/)
- [homer](https://github.com/bastienwirtz/homer)
- [system-upgrade-controller](https://github.com/rancher/system-upgrade-controller)
- [velero](https://velero.io/)
- [rook-ceph](https://rook.io/)
- [plex](https://www.plex.tv/)

## :memo:&nbsp; Prerequisites

### :computer:&nbsp; Nodes

Already provisioned Bare metal or VMs with any modern operating system like Ubuntu, Debian or CentOS.

### :wrench:&nbsp; Tools

:round_pushpin: These tools are pre-installed in a [Vagrant VM](https://www.vagrantup.com), purpose built to mangage this cluster. You can find that repo [here](https://github.com/jgilfoil/cluster-infra)

| Tool                                                               | Purpose                                                             | Minimum version | Required |
|--------------------------------------------------------------------|---------------------------------------------------------------------|:---------------:|:--------:|
| [k3sup](https://github.com/alexellis/k3sup)                        | Tool to install k3s on your nodes                                   |    `0.10.2`     |    ✅     |
| [kubectl](https://kubernetes.io/docs/tasks/tools/)                 | Allows you to run commands against Kubernetes clusters              |    `1.21.0`     |    ✅     |
| [flux](https://toolkit.fluxcd.io/)                                 | Operator that manages your k8s cluster based on your Git repository |    `0.12.3`     |    ✅     |
| [SOPS](https://github.com/mozilla/sops)                            | Encrypts k8s secrets with GnuPG                                     |     `3.7.1`     |    ✅     |
| [GnuPG](https://gnupg.org/)                                        | Encrypts and signs your data                                        |    `2.2.27`     |    ✅     |
| [pinentry](https://gnupg.org/related_software/pinentry/index.html) | Allows GnuPG to read passphrases and PIN numbers                    |     `1.1.1`     |    ✅     |
| [direnv](https://github.com/direnv/direnv)                         | Exports env vars based on present working directory                 |    `2.28.0`     |    ❌     |
| [pre-commit](https://github.com/pre-commit/pre-commit)             | Runs checks during `git commit`                                     |    `2.12.0`     |    ❌     |
| [kustomize](https://kustomize.io/)                                 | Template-free way to customize application configuration            |     `4.1.0`     |    ❌     |
| [helm](https://helm.sh/)                                           | Manage Kubernetes applications                                      |     `3.5.4`     |    ❌     |



### :warning:&nbsp; pre-commit

Install [pre-commit](https://pre-commit.com/) and the pre-commit hooks that come with this repository.
[sops-pre-commit](https://github.com/k8s-at-home/sops-pre-commit) will check to make sure you are not by accident commiting your secrets un-encrypted.

After pre-commit is installed on your machine run:

```sh
pre-commit install-hooks
```

## :open_file_folder:&nbsp; Repository structure

The Git repository contains the following directories under `cluster` and are ordered below by how Flux will apply them.

- **base** directory is the entrypoint to Flux
- **crds** directory contains custom resource definitions (CRDs) that need to exist globally in your cluster before anything else exists
- **core** directory (depends on **crds**) are important infrastructure applications (grouped by namespace) that should never be pruned by Flux
- **apps** directory (depends on **core**) is where your common applications (grouped by namespace) could be placed, Flux will prune resources here if they are not tracked by Git anymore

```
cluster
├── apps
│   ├── default
│   ├── networking
│   └── system-upgrade
├── base
│   └── flux-system
├── core
│   ├── cert-manager
│   ├── metallb-system
│   ├── namespaces
│   └── system-upgrade
└── crds
    └── cert-manager
```

## Setup
See full documentation under [docs](docs/README.md)

## :handshake:&nbsp; Thanks

Big shout out to the [K8s@Home](https://github.com/k8s-at-home/template-cluster-k3s) team for the majority of the work that went into this cluster's bootstrap and their continuied maintenance of much of the underlying charts and images that underpin it's services.
