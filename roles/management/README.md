# Management role

This role implements a sequence of tasks required to deploy Informix database management scripts and supporting tools.

## Table of contents

* [Overview][1]
* [Configuration][2]
    * [Informix maintenance jobs][3]

[1]: #overview
[2]: #configuration
[3]: #informix-maintenance-jobs

## Overview

This role encapsulates the tasks required to deploy database management scripts, cron jobs, and supporting tools to cloud-based hosts.

## Configuration

The following sections detail the different areas of configuration supported by this role.

### Informix maintenance jobs

The `informix_maintenance_jobs` variable can be used to configure scheduled maintenance jobs for Informix databases. This is used primarily as a group or host variable to configure maintenance jobs specific to environments or individual hosts and is generally limited to the _live_ environment where alerts and statistics are required. The absence of a group variable for a given environment means that _no_ scheduled jobs will be configured.

`informix_maintenance_jobs` should be defined as a list. Each item represents a single scheduled job for the Informix user matching the user name of the variable `informix_user`. The following parameters are required for each list item:

| Name                 | Default | Description                                                                          |
|----------------------|---------|--------------------------------------------------------------------------------------|
| `name`               |         | A description of the job. This parameter should be unique across all jobs defined for a given group. |
| `day_of_week`        |         | Day of the week that the job should run (`0-6` for Sunday-Saturday, `*`, and so on). |
| `day_of_month`       |         | Day of the month the job should run (`1-31`, `*`, `*/2`, and so on).                 |
| `minute`             |         | Minute when the job should run (`0-59`, `*`, `*/2`, and so on).                      |
| `hour`               |         | Hour when the job should run (`0-23`, `*`, `*/2`, and so on).                        |
| `script`             |         | The name of the script to execute. This should correspond to a script that is present in the [ais-tuxedo-scripts](https://github.com/companieshouse/ais-tuxedo-scripts) artefact being used at the time the role is executed, and is expected to exist in a `scripts/<user>` subdirectory in the expanded artefact, where `<user>` matches the value of the variable `informix_user` (default: `informix`).

For example, to execute the `level_zero_backup` script at midnight every day:

```yaml
informix_maintenance_jobs:
  - name: Perform level zero backup for EF database
    day_of_week: "*"
    day_of_month: "*"
    minute: "0"
    hour: "0"
    script: "level_zero_backup ef"
```
