# ais-tuxedo-stack

This project encapsulates the infrastructure and deployment code for AIS Tuxedo services and includes separate branches for each:

* `infrastructure` - Infrastructure code for building AIS Tuxedo services in AWS
* `deployment` - Deployment code for deploying AIS Tuxedo services to AWS

The remainder of this document contains information that is specific to the branch in which it appears.

## Infrastructure

This branch (i.e. `deployment`) contains the deployment code responsible for deploying AIS Tuxedo services and is composed of multiple Ansible roles which are used primarily in CI to provision Informix database servers and deploy groups of AIS Tuxedo services to a given environment.

Refer to the documentation for each of the following roles for more information:

* [database](roles/database/README.md) - for provisioning Informix database server(s), dbspaces, chunks
