# Database role

This role is intended for one-time bootstrapping of IBM Informix server instances and is responsible for creating Informix configuration files (`onconfig` and `sqlhosts`) as well as initialising the root dbspace and preparing additional dbspaces and chunks.

:warning: If the target host(s) include _existing_ dbspaces or chunks then there may be a **risk of data loss** when using this role. See [Provisioning hosts with existing dbspaces](#provisioning-hosts-with-existing-dbspaces) for more information if this role needs to be applied to hosts that contain existing data.

## Table of contents

* [Assumptions][1]
* [Informix database configuration][2]
  * [Server connections configuration][3]
    * [Default server connections configuration][4]
  * [DBSpaces configuration][5]
  * [Chunk configuration][6]
  * [Example configuration][7]
* [Provisioning hosts with existing dbspaces][8]

[1]: #assumptions
[2]: #informix-database-configuration
[3]: #server-connections-configuration
[4]: #default-server-connections-configuration
[5]: #dbspaces-configuration
[6]: #chunk-configuration
[7]: #example-configuration
[8]: #provisioning-hosts-with-existing-dbspaces

## Assumptions

The following assumptions are made:

* The target host(s) have **not** been previously provisioned by this role and **no** dbspaces or chunks exist
* There are **no** active `oninit` processes on the target host(s) when this role is executed
* Each database server instance has a corresponding user account of the same name for administering that server instance (n.b. active `oninit` proceesses will be owned by `root` as many Informix binaries make use of the `setuid` and `setgid` flags)

## Informix database configuration

The `informix_service_config` variable controls the configuration of Informix databases, dbspaces, chunks and server connections. Project defaults that cater for the the initial cloud migration of on-premise Informix servers to AWS have been specified in `defaults/main.yml`.

The`informix_service_config` variable should be defined as a dictionary of dictionaries, whose keys represent unique server instances of Informix (analgous to the 'server name'):

```yaml
informix_service_config:
  server1:
    ...
  server2:
    ...
```

:notebook: All configuration parameters that follow are required unless marked _optional_.

Each dictionary representing a server (e.g. `server1` and `server2` in the above example) requires the following parameters:

| Name                 | Default | Description                                            |
|----------------------|---------|--------------------------------------------------------|
| `server_id`          |         | A unique numeric identifier for this server instance   |
| `server_port`        |         | _Optional_. The port number this server instance will bind to for TCP/IP connections when using the default `server_connections` value. If a value has been provided for `server_connections` then `server_port` should be ommited, and instead a port number (if required) should be specified in the relevant connection item of the `server_connections` list. |
| `server_connections` | See [Server connections][3] for defaults. | A list of dictionaries representing client/server connections for this server (i.e. the `sqlhosts` file configuration). See [Server connections][3] for more details. |
| `dbspaces`           |         | A dictionary of uniquely named dbspaces. Must include at least a `root` dbspace. See [Dbspaces configuration][5] for more details.

Additional global configuration variables are used for the purposes detailed below:

| Name                 | Default | Description                                            |
|----------------------|---------|--------------------------------------------------------|
| `informix_chunk_store_path` | `/data/informix/chunks` | The path of the directory for storing cooked files for dbspace chunks (when not using raw disks). This variable should be referenced in the [Dbspaces configuration][5] `path` option for any dbspace chunks that are to be represented using cooked files (e.g. `{{ informix_chunk_store_path }}/rootdbs`).
| `informix_server_name_suffix`        |         | _Optional_. An optional suffix value that will be appended to the Informix server name in configuration files and environment variables to differentiate servers when using High Availability Data Replication (HDR). For example, the values `_primary` and `_secondary`. Such configuration should be specified for individual hosts using dynamic inventory `keyed_groups`. |

### Server connections configuration

The _optional_ `server_connections` parameter must comprise a list of dictionaries. See [Default server connections configuration][4] for information regarding default connections. Each dictionary may specify the following options:

| Name                 | Default |                         | Field name (`sqlhosts` file) |
|----------------------|---------|-------------------------|------------------------------|
| `server_name`        |         | A unique database server name for this connection. | `dbservername` |
| `connection_type`    |         | The connection type to use (e.g. `onipcshm` for shared memory segment or `onsoctcp` for TCP/IP connection) | `nettype` |
| `host`               |         | The host computer for the database server. | `hostname` |
| `service_or_port`    |         | The service name or port number dependent upon `connection_type`. | `servicename` |
| `options`            |         | Any options that describe or limit the connection | `options` |

#### Default server connections configuration

In the absence of an explicit `server_connections` parameter, the default value provides two connections for the server:

1. A _shared memory_ connection — the `server_name` value for this connection will be set using the parent dictionary key that represents the server instance that the connection belongs to in `informix_service_config` (e.g. `server1` in the example given during the introductory section of [Informix database configuration][2])
2. A socket connection for TCP/IP protocol connections from client applications — the `server_name` value for this connection will be set using the parent dictionary key that represents the server instance that the connection belongs to in `informix_service_config` followed by a `tcp` suffix (e.g. `server1tcp` in the example given during the introductory section of [Informix database configuration][2])

### DBSpaces configuration

The `dbspaces` parameter must be a dictionary of dictionaries whose keys represent uniquely named dbspaces for the server that they belong to. A `root` key must be defined for each dbspace—representing the root dbspace—and each dbspace dictionary may specify the following options:

| Name                 | Default |                                             |
|----------------------|---------|---------------------------------------------|
| `initial_chunk`      |         | A dictionary representing the initial chunk for the root dbspace. See [Chunk configuration][6] for more details. |
| `additional_chunks`  |         | _Optional_. A list of one or more dictionaries representing additional chunks to be added to the dbspace. See [Chunk configuration][6] for more details. |

### Chunk configuration

The `initial_chunk` and `additional_chunks` parameters both represent chunks belonging to a dbspace. The former parameter is mandatory and takes the form of a dictionary, while the later is an optional list of dictionaries. In either case, the following options are supported:

| Name           | Default |                                                              |
|----------------|---------|--------------------------------------------------------------|
| `path`         |         | The path to the block device or file on disk for this chunk. |
| `offset_in_kb` |         | The offset in KiB for this chunk.                            |
| `size_in_kb`   |         | The size in KiB for this chunk.                              |

Observations to consider when configuring dbspace chunks:

* Chunks are assumed to be cooked files if the `path` does not refer to a block device, and a suitable file will be created at the specified path using `informix:informix` ownership and `0660` permissions before adding the chunk to a dbspace.
* Chunks that belong to different cooked files should use an offset value of `0`. Chunks that belong to the same cooked file as other chunks should typically use an `offset_in_kb` value equal the sum of the `offset_in_kb + size_in_kb` of the previous chunk with the same path.
* Chunks that belong to raw disks should use an offset sufficient to ensure that they do not overlap with existing data on the disk (e.g. filesystem metadata) or other chunks.

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

:warning: This role is _not_ idempotent and there is a **risk of data loss** if the role is executed against hosts whose user accounts contain existing dbspaces and chunks. A lock file is created for each user provisioned by this role to provide a basic level of protection against this. The presence of such lock files are used to distinguish any user accounts that were previously provisioned with this role, and the role will fail to execute until manual action is taken.

To provision a user on a remote host with this role a second time:

* Confirm that there are no dbpsaces or chunks present for the user account(s) on the remote host(s) (i.e. check all `path` references in the `informix_service_config` configuration for the relevant user account(s) and confirm those paths do not contain actual data on the remote host(s))
* Remove the lock file `/etc/ais-tuxedo-stack-database-provisioned-<username>` on the remote host(s)
* Stop any active `oninit` processes on the remote host(s)
* Remove any shared memory segements that were created by the `oninit` processes
* Rerun this role against the same user account(s) and host(s)
