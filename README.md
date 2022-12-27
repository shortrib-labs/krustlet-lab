# vSphere Krustlet Cluster

Easily create a Kubernetes cluster on vSphere that runs WebAssembly workloads.
Uses [kURL](https://kurl.sh), [Terraform](https://terraform.io), and
[Krustlet](https://krustlet.dev).

## Goals and Audience

I created this project as a simple way to spin up a clsuter with Krustlet nodes
to learn more about WebAssembley workloads. The initial audience was me, but I
imagine it could be usefult to anyone wwanting to learn more about the
intersection of Kubernetes and WebAssembly.

## Requirements

### Required

* A vSphere cluster
* Your favorite editor
* A Unix-y workstation (WSL should work)
* Make
* Terraform
* Direnv
* SOPS (for secrets management, see below)
* GPG (also fro secrets management)

## Customizing for Your Environment

To use this repostiory in your enviorment, you'll need to create
a file named `params.yaml` in the `secrets` directory. The content
of the file is documented in the file 
[`secrets/REDACTED-params.yaml`](secrets/REDACTED-params.yaml). 
Copy the redacted version to `params.yaml` and edit as apporpriate 
to connect to your cluster, specify the size of your node, etc.

## Creating a Cluster

The cluster is created using [Terraform](https://terraform.io), but there's a
`Makefile` to make basic operations easier. Creating a cluster with the latest
versions from kURL is as simple as

```shell
$ make cluster
```

The output at the end will show the IP address for your control plane node so
that you can connect to it. It will also download a kubeconfig and set `direnv`
will set `$KUBECONFIG` to point to that file.

By default, the node is created as a multi-node cluster with a single-node
control plane, 2 tradiitional Kubernetes workers, and one Krustlet node.
installer. The kURL installer is defined in the file `kurl-installer.yaml` and
has only a couple of variables from the default `latest` installl. To use a
custom kURL installer, including a KOTS install with an embedded cluster, set
the variable `kurl_script`, for example, to use the latest k3s:

```shell
$ make node kurl_script="curl https://kurl.sh/k3s | sudo bash"
```

## Destroying the Cluster

When you're done with your cluster, you can easily destroy it 
with 

```shell
$ make destroy
```

## Protecting Secrets

There are some secrts in the `params.yaml` file, and I don't like
losing track of them so I put them in my repo. They are managed
with [SOPS](https://github.com/mozilla/sops)

The script is written in Python and uses a couple of libraries
to make it a bit more ergonomic. If you want to manage your secrets
in the repositroy as well, you'll need to fork this repo and make
changes to the SOPS configuration in `.sops.yaml` (and put your
public key into `.sops.pub.asc`).

There are a couple of `make` targets to facilitate working with
the encrypted file.

```shell
$ make encrypt
```

to encrypt the `params.yaml` file, and 

```shell
$ make decrypt
```

to decrypt it.
