variable "ami_owner_id" {
  type        = string
  description = "The AMI owner ID."
}

variable "ami_version_pattern" {
  type        = string
  description = "The pattern to use when filtering for AMI version by name."
  default     = "*"
}

variable "application_subnet_pattern" {
  type        = string
  description = "The pattern to use when filtering for application subnets by 'Name' tag."
  default     = "sub-application-*"
}

variable "aws_account" {
  type        = string
  description = "The name of the AWS account in which resources will be provisioned."
}

variable "default_log_retention_in_days" {
  type        = number
  description = "The default log retention period in days to be used for CloudWatch log groups."
  default     = 7
}

variable "deployment_cidrs" {
  type        = list(string)
  description = "A list of strings representing IPv4 CIDR addresses from which applications will be deployed to Tuxedo instances via Ansible."
}

variable "dns_zone_suffix" {
  type        = string
  description = "The common DNS hosted zone suffix used across accounts."
  default     = "heritage.aws.internal"
}

variable "environment" {
  type        = string
  description = "The environment name to be used when provisioning AWS resources."
}

variable "informix_services" {
  type        = map(number)
  description = "A map whose key-value pairs represent Informix servers and associated port numbers."
  default = {
    ais = 6000
  }
}

variable "instance_count" {
  type        = number
  description = "The number EC2 instances to create."
  default     = 1
}

variable "instance_type" {
  type        = string
  description = "The instance type to use for EC2 instances."
  default     = "t3.small"
}

variable "lvm_block_devices" {
  type = list(object({
    aws_volume_size_gb              = string
    filesystem_resize_tool          = string
    lvm_logical_volume_device_node  = string
    lvm_physical_volume_device_node = string
  }))
  description = "A list of objects representing LVM block devices; each LVM volume group is assumed to contain a single physical volume and each logical volume is assumed to belong to a single volume group; the filesystem for each logical volume will be expanded to use all available space within the volume group using the filesystem resize tool specified; block device configuration applies only on resource creation. Set the 'filesystem_resize_tool' and 'lvm_logical_volume_device_node' fields to empty strings if the block device contains no filesystem and should be excluded from the automatic filesystem resizing, such as when the block device represents a swap volume."
  default     = []
}

variable "region" {
  type        = string
  description = "The AWS region in which resources will be created."
}

variable "root_volume_size" {
  type        = number
  description = "The size of the root volume in gibibytes (GiB)."
  default     = 20
}

variable "service" {
  type        = string
  description = "The service name to be used when creating AWS resources."
  default     = "tuxedo"
}

variable "service_subtype" {
  type        = string
  description = "The service subtype name to be used when creating AWS resources."
  default     = "ais"
}

variable "ssh_master_public_key" {
  type        = string
  description = "The SSH master public key; EC2 instance connect should be used for regular connectivity."
}

variable "tuxedo_log_groups" {
  type = map(list(
    object({
      name                  = string
      log_retention_in_days = optional(number)
      kms_key_id            = optional(string)
    })
  ))
  description = "A map of lists whose keys represent Tuxedo service groups. Each list object represents a single CloudWatch log group and is expected to specify at least a 'name' attribute. Optional 'log_retention_in_days' and 'kms_key_id' attributes can be used to override the default values ('log_retention_in_days' defaults to the value of the 'default_log_retention_in_days' variable, and 'kms_key_id' defaults to a KMS key identifier value sourced from Hashicorp Vault)."
  default = {
    ais = [
      { name : "domain" },
      { name : "domaudit" },
      { name : "ULOG" }
    ]
  }
}

variable "tuxedo_services" {
  type        = map(number)
  description = "A map whose key-value pairs represent Tuxedo service groups and associated port numbers."
  default = {
    ais = 38000
  }
}

variable "team" {
  type        = string
  description = "The team name for ownership of this service."
  default     = "Platform"
}

variable "user_data_merge_strategy" {
  type        = string
  default     = "list(append)+dict(recurse_array)+str()"
  description = "Merge strategy to apply to user-data sections for cloud-init."
}
