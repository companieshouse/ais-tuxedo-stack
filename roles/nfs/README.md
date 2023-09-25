# NFS role

This role implements a sequence of tasks for the configuration of NFS mounts.

## Table of contents

* [NFS Configuration][1]

[1]: #nfs-configuration

## NFS Configuration

NFS file system mounts are configuration using an `nfsmounts` group (or host) variable. The `nfsmounts` variable is defined as a list of dictionaries, each of which supports the following parameters:

| Name          | Default | Description                                                                           |
|---------------|---------|---------------------------------------------------------------------------------------|
| `path`        |         | The path on the remote system being provisioned which will be used as the mount point for the NFS file system. |
| `src`         |         | The source of the NFS file system in the form of the hostname or IP address of the NFS server and the directory being exported (e.g. `1.2.3.4:/exported`). |
| `opts`        |         | _Optional_. Options for the NFS file system that will be added to the file system table configuration (i.e. `/etc/fstab`) in the form of a single comma-separated string.
| `symlink`     |         | _Optional_. An optional path that will be used to create a symbolic link to the mount `path` specified. |
