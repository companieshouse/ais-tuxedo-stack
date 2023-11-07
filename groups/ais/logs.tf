resource "aws_cloudwatch_log_group" "tuxedo" {
  for_each = local.tuxedo_log_groups

  name              = each.key
  retention_in_days = each.value.log_retention_in_days
  kms_key_id        = each.value.kms_key_id

  tags = merge(local.common_tags, {
    TuxedoServerType = each.value.tuxedo_service
    TuxedoLogName    = each.value.log_name
    TuxedoLogType    = each.value.log_type
  })
}

resource "aws_cloudwatch_log_group" "cloudwatch" {
  name              = "${var.service_subtype}-${var.service}-cloudwatch"
  retention_in_days = var.default_log_retention_in_days
  kms_key_id        = local.logs_kms_key_id

  tags = merge(local.common_tags, {
    LogName = "cloudwatch"
  })
}
