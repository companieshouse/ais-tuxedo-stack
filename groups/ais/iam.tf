module "instance_profile" {
  source = "git@github.com:companieshouse/terraform-modules//aws/instance_profile?ref=tags/1.0.262"
  name   = "${var.service_subtype}-${var.service}-profile"

  cw_log_group_arns = formatlist("%s:*", local.tuxedo_log_group_arns)
  enable_ssm        = true
  kms_key_refs      = [local.ssm_kms_key_id]
  s3_buckets_write  = [local.session_manager_bucket_name]
}
