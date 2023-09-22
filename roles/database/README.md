# Database role

This role is intended for one-time provisioning of IBM Informix server instances, and is responsible for creating configuration files (`onconfig` and `sqlhosts`) as well as initialising the root dbspace and preparing additional dbspaces and chunks as required.

:warning: If the target host(s) contains _existing_ dbspaces or chunks there may be a **risk of data loss** when using this role. For additional safety, this role creates a lock file in `/etc` and will refuse to execute again so long as the lock file exists. See [Provisioning hosts with existing dbspaces](#provisioning-hosts-with-existing-dbspaces) for more information should this role need to be applied to hosts that contain existing data.

## Table of contents

* [Assumptions][1]
* [Informix database configuration][2]
  * [Server connections configuration][3]
    * [Default server connections configuration][4]
    * [Host specific server connections][5]
  * [DBSpaces configuration][6]
  * [Chunk configuration][7]
  * [Informix user configuration][8]
  * [Informix event alarms configuration][9]
  * [Example configuration][10]
* [Provisioning hosts with existing dbspaces][11]

[1]: #assumptions
[2]: #informix-database-configuration
[3]: #server-connections-configuration
[4]: #default-server-connections-configuration
[5]: #host-specific-server-connections
[6]: #dbspaces-configuration
[7]: #chunk-configuration
[8]: #informix-user-configuration
[9]: #informix-event-alarms-configuration
[10]: #example-configuration
[11]: #provisioning-hosts-with-existing-dbspaces

## Assumptions

The following assumptions are made:

* The target host(s) have **not** been previously provisioned by this role and **no** dbspaces or chunks exist
* There are **no** active `oninit` processes on the target host(s) when this role is executed (n.b. active `oninit` processes will be owned by `root` as many Informix binaries make use of the `setuid` and `setgid` flags)
* Each database server instance has a corresponding user account of the same name on the target host for administering that server instance

## Informix database configuration

The `informix_service_config` dictionary variable controls the configuration of Informix databases, dbspaces, chunks and server connections. This variable should be defined as a dictionary of dictionaries, whose keys represent unique database server instances (such keys are analogous to the 'server name' in this context):

```yaml
informix_service_config:
  server1:
    ...
  server2:
    ...
```

:notebook: All configuration keys that follow are required unless marked _optional_.

Each nested dictionary within `informix_service_config` represents an individual database server (e.g. `server1` and `server2` in the above example) and supports the following key:

| Name                 | Default | Description                                            |
|----------------------|---------|--------------------------------------------------------|
| `server_id`          |         | A unique numeric identifier for this server instance   |
| `server_port`        |         | _Optional_. The port number this server instance will bind to for TCP/IP connections when using the default `server_connections` value. If a `server_connections` key has been defined then `server_port` should be omitted, and the port number should be specified in the relevant field of the `server_connections` list (if required for that connection type). |
| `server_aliases`     |         | _Optional_. A comma-separated string containing one or more database server aliases. |
| `server_connections` | See [Server connections configuration][3] for defaults. | A list of dictionaries representing client/server connections for this server (for constructing the `sqlhosts` configuration file). See [Server connections configuration][3] for more details. Connections specified for this key are common to all remote hosts provisioned by this role. To specify host-specific connections see [Host specific server connections][5]. |
| `dbspaces`           |         | A dictionary of uniquely named dbspaces. Must include at least a `root` dbspace. See [Dbspaces configuration][6] for more details.
| `users`              |         | _Optional_. A list of dictionaries specifying user accounts for Informix connections. See [Informix user configuration][8] for more information. |
| `logical_log_size`   | `10000` | _Optional_. The size of each logical log in kilobytes. |
| `logical_log_number_files` | `100` | _Optional_. The number of logical log files. |
| `event_alarms_enabled` | `false` | _Optional_. A boolean value representing whether event alarms are enabled or not. See [Informix event alarms configuration][9] for more information. |

Additional global configuration variables are used for the purposes detailed below:

| Name                 | Default | Description                                            |
|----------------------|---------|--------------------------------------------------------|
| `informix_chunk_store_path` | `/data/informix/chunks` | The path of the directory for storing cooked files for dbspace chunks (when not using raw disks). This variable should be referenced in the [Dbspaces configuration][6] `path` option for any dbspace chunks that are to be represented using cooked files (e.g. `{{ informix_chunk_store_path }}/rootdbs`).
| `informix_server_name_suffix`        |         | _Optional_. An optional suffix value that will be appended to the Informix server name in configuration files and environment variables to differentiate servers when using High Availability Data Replication (HDR). For example, the values `_primary` and `_secondary`. Such configuration should be specified for individual hosts using dynamic inventory `keyed_groups`. |

### Server connections configuration

If defined, the _optional_ `server_connections` key must specify a list of dictionaries. If omitted, a default set of server connections will be used; see [Default server connections configuration][4] for more information. Each dictionary supports the following keys:

| Name                 | Default |                         | `sqlhosts` configuration file field name |
|----------------------|---------|-------------------------|------------------------------|
| `server_name`        |         | A unique database server name for this connection. | `dbservername` |
| `connection_type`    |         | The connection type to use (e.g. `onipcshm` for shared memory segment or `onsoctcp` for TCP/IP connection) | `nettype` |
| `host`               |         | The host computer for the database server. | `hostname` |
| `service_or_port`    |         | The service name or port number dependent upon `connection_type`. | `servicename` |
| `options`            |         | Any options that describe or limit the connection | `options` |

#### Default server connections configuration

A default set of server connections will be used if no `server_connections` are specified for a given database server (see [Informix database configuration][2]) _and_ no host-specific connections have been specified for the same database server in the `informix_host_specific_server_connections` variable (see [Host specific server connections][5]). These default connections include:

1. A _shared memory_ connection — the `server_name` value for this connection will be set using the parent dictionary key that this connection belongs to (e.g. `server1` in the example given during the introductory section of [Informix database configuration][2])
2. A socket connection using TCP/IP for client applications — the `server_name` value for this connection will be set using a combination of the parent dictionary key that this connection belongs to and a `tcp` suffix (e.g. `server1tcp` in the example given during the introductory section of [Informix database configuration][2])

#### Host specific server connections

Server connections specified using the `server_connections` key (see [Informix database configuration][2]) are common to _all_ remote hosts provisioned by this role. To define host-specific connections, add the variable `informix_host_specific_server_connections` to one or more group or host vars files. This variable should be defined as a dictionary of dictionaries whose keys represent the same database server instances as those used in the `informix_service_config` variable (see [Informix database configuration][2]).

For example, to define a connection that is specific to a remote EC2 host whose name tag matches the value `ais-tuxedo-staging-1`, add the following configuration to the group vars file named `tag_Name_fil_tuxedo_staging_1`:

```yaml
informix_host_specific_server_connections:
  ef:
    - server_name: example
      connection_type: onsoctcp
      host: instance-1.fil.tuxedo.staging.heritage.aws.internal
      service_or_port: 1234
```

In this example, the single connection above would be combined with any connections already specified in the `server_connections` key of the `informix_service_config` variable for the same top-level database server named `ef`. If the `informix_service_config` contains no shared `server_connections`, then only the single host-specific connection above will be used for the matching remote host.

### DBSpaces configuration

The `dbspaces` key must be a dictionary of dictionaries whose keys represent uniquely named dbspaces for the server that they belong to. A `root` key must be defined for each dbspace—representing the root dbspace—and each dbspace dictionary may specify the following options:

| Name                 | Default |                                             |
|----------------------|---------|---------------------------------------------|
| `initial_chunk`      |         | A dictionary representing the initial chunk for the root dbspace. See [Chunk configuration][7] for more details. |
| `additional_chunks`  |         | _Optional_. A list of one or more dictionaries representing additional chunks to be added to the dbspace. See [Chunk configuration][7] for more details. |

### Chunk configuration

The `initial_chunk` and `additional_chunks` keys both represent chunks belonging to a dbspace. The former is mandatory and takes the form of a dictionary, while the later is an optional list of dictionaries. In either case, the following keys are supported:

| Name           | Default |                                                                |
|----------------|---------|----------------------------------------------------------------|
| `path`         |         | The path to a character device or file on disk for this chunk. |
| `offset_in_kb` |         | The offset in kB for this chunk.                               |
| `size_in_kb`   |         | The size in kB for this chunk.                                 |

Observations to consider when configuring dbspace chunks:

* Chunks are assumed to be cooked files if the `path` does not refer to a block device, and a suitable file will be created at the specified path using `informix:informix` ownership and `0660` permissions before adding the chunk to a dbspace.
* Chunks that belong to different cooked files should use an offset value of `0`. Chunks that belong to the same cooked file as other chunks should typically use an `offset_in_kb` value equal the sum of the `offset_in_kb + size_in_kb` of the previous chunk with the same path.
* Chunks that belong to raw disks should use an offset sufficient to ensure that they do not overlap with existing data on the disk or other chunks.

### Informix user configuration

If defined, the _optional_ `users` key must specify a list of dictionaries. Each dictionary supports the following keys:

| Name                 | Default |                                                                                                 |
|----------------------|---------|-------------------------------------------------------------------------------------------------|
| `name`               |         | A unique user account name for connectivity to the database server under which this key exists. |


User configuration will be read from HashiCorp Vault using the path `{{ vault_base_path }}/informix`, which is expected to contain a JSON object with a top-level key corresponding to the database server name. User names should be specified within a `users` key as an object containing a single `password` key and string value. For example, given a single database server named `example-server` and user named `example-user`:

```json
{
  "example-server": {
    "users": {
      "example-user": {
        "password": "..."
      }
    }
  }
}
```

All user accounts are created as non-login accounts using `/sbin/nologin` as the default shell, with no password expiry.

### Informix event alarms configuration

Event alarms configuration will be read from HashiCorp Vault using the path `{{ vault_base_path }}/informix`, which is expected to contain a JSON object with a top-level key corresponding to the database server name. An `event_alarms` key should be set to an object containing the keys `email_addresses` and `level` which are used to configure the event alarms. The value for `level` should correspond to the desired [event severity](https://www.ibm.com/docs/en/informix-servers/14.10?topic=alarms-event-alarm-parameters#ids_adr_0674__title__3) level for alarms. For example, given a single database server named `example-server` and using the email address `user@nowhere.com` for events of severity level `3` or greater:

```json
{
  "example-server": {
    "event_alarms": {
      "email_addresses": "user@nowhere.com",
      "level": "3"
    }
  }
}
```

### Example configuration

The example that follows shows how to define the configuration for a single server instance named `server1` that meets the following criteria:

* One Informix server instance `server1` with server identifier `1`
* A `root` dbspace composed of one initial cooked file chunk of size 1GiB
* An additional `data` dbspace with initial cooked file chunk of size 1GiB and an additional chunk of size 2GiB (both belonging to the same filesystem object)
* The two [default connection types][4] (i.e. a shared memory segment and TCP/IP connection respectively) with port `1234` used for TCP/IP connectivity

```yaml
informix_service_config:
  server1:
    server_id: 1
    server_port: 1234
    dbspaces:
      root:
        initial_chunk:
          path: "/informixchunks/rootdbs"
          offset_in_kb: 0
          size_in_kb: 1048576
      data:
        initial_chunk:
          path: "/informixchunks/datadbs"
          offset_in_kb: 0
          size_in_kb: 1048576
        additional_chunks:
          - path: "/informixchunks/datadbs"
            offset_in_kb: 1048576
            size_in_kb: 1048576
```

## Provisioning hosts with existing dbspaces

:warning: This role is _not_ idempotent and there is a **risk of data loss** if the role is executed against hosts that contain existing dbspaces and chunks. A lock file is created in `/etc` for each database server instance provisioned by this role to provide a basic level of protection against this. These lock files are used to distinguish whether a database server was previously provisioned with this role, and the role will refuse to execute again until manual intervention is taken.

To provision a database server on a remote host with this role a second time:

* Confirm that there are no dbpsaces or chunks present for the database server(s) on the remote host(s) (i.e. check all `path` references in the `informix_service_config` configuration and confirm that those paths, whether cooked files or raw disks, do not contain actual data on the remote host(s))
* Remove the corresponding lock file(s) for the database server(s) affected from `/etc`—these follow the naming convention `ais-tuxedo-stack-database-provisioned-<server>`
* Stop any active `oninit` processes on the remote host(s) for the affected database server(s)
* Remove any shared memory segments that were created by `oninit` processes for the affected database server(s)
* Rerun this role against the same database server(s) and host(s)
