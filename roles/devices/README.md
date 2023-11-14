# Devices role

This role implements a sequence of tasks for the configuration of iSCSI devices attached to remote servers. It is intended to be executed before the [database](/roles/database/README.md) role, in order to provision storage devices for Informix databases. This includes scanning for iSCSI targets, creating multipath configuration, adding udev rules, setting up raw character device nodes, and optionally creating filesystems on supplementary iSCSI devices not directly used by Informix.

:warning: There may be a **risk of data loss** when using this role against previously provisioned hosts. For additional safety, this role creates a lock file in `/etc` and will refuse to execute again so long as the lock file exists. See [Reprovisioning Hosts](#reprovisioning-hosts) for more information should this role need to be applied to hosts that contain existing data.

## Table of contents

* [iSCSI Devices][1]
  * [Filesystem Configuration][2]
* [Reprovisioning Hosts][3]

[1]: #iscsi-devices
[2]: #filesystem-configuration
[3]: #reprovisioning-hosts

## iSCSI Devices

iSCSI devices are configured using a combination of the `iscsi_devices` group (or host) variable and external configuration stored in Hashicorp Vault (internally known by the host fact named `iscsi_vault_config`).

---

The `iscsi_devices` variable is defined as a list of dictionaries, each of which supports the following parameters:

| Name                        | Default | Description                                                                           |
|-----------------------------|---------|---------------------------------------------------------------------------------------|
| `alias`                     |         | A unique alias for the storage device. This is used to create a symbolic link of the same name in `/dev` pointing at the raw character device node, and is used to give the path context when referenced in Informix configuration (e.g. a symbolic link `/dev/scud` carries more context than the character device node it points at, such as `/dev/raw/raw1`). |
| `raw_character_device_path` |         | A unique raw character device node path. This should take the form `/dev/raw/raw<N>` where `<N>` is a non-negative integer value (e.g. `/dev/raw/raw1`, `/dev/raw/raw2` and so on). See [raw(8)](https://www.man7.org/linux/man-pages/man8/raw.8.html) for more information. |
| `filesystem`                |         | _Optional_. A dictionary specifying filesystem configuration. See [Filesystem Configuration][2] for more information. |

---

The internal host fact `iscsi_vault_config` is set during execution of this role, and its value is sourced from Hashicorp Vault at the path specified in the role variable `vault_path`. This configuration takes the form of a JSON object with the following attributes:

```json
{
  "<ansible-inventory-host>": {
    "iscsi_device_wwids": {
      "<alias>": "<wwid>"
    }
    "iscsi_initiator_name": "<iscsi-initiator-name>",
    "iscsi_portal_ips": [
      "<ip-address>"
    ]
  }
}
```

### Filesystem Configuration

If defined, the _optional_ `filesystem` key dictionary must specify the following keys:

| Name         | Default | Description                                                                           |
|--------------|---------|---------------------------------------------------------------------------------------|
| `type`       |         | The filesystem type to be created. Refer to the Ansible [filesystem module documentation](https://docs.ansible.com/ansible/latest/collections/community/general/filesystem_module.html) for valid options. |
| `mount_path` |         | That path at which the filesystem will be mounted. The target mount path will be created if it does not already exist, with `0770` permissions and user and group ownership defined by the variables `informix_service_user` and `informix_service_group` respectively. |

## Reprovisioning Hosts

:warning: There is a **risk of data loss** if the role is executed against hosts that have previously been provisioned. A lock file is created in `/etc` by this role to provide a basic level of protection against this. The role will refuse to execute again until manual intervention is taken.

To provision a remote host with this role a second time, accepting the potential risk of data loss:

* Stop any active Informix `oninit` processes on the remote host(s) that may be using the storage device(s)
* Remove the corresponding lock file from remote host(s) at `/etc/ais-tuxedo-stack-iscsi-devices-provisioned`
* Rerun this role against the same host(s)

