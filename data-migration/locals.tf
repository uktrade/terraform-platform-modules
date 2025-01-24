locals {
  role_name   = "${substr(var.destination_bucket_identifier, 0, 48)}-S3MigrationRole"
  policy_name = "${substr(var.destination_bucket_identifier, 0, 46)}-S3MigrationPolicy"

  # To ensure that this isn't a breaking change, we accept just the source_bucket_arn/worker_role_arn config or the additional_source_bucket_arn/additional_worker_role_arns
  worker_role_list = try(concat([var.config.worker_role_arn], var.config.additional_worker_role_arn), [var.config.worker_role_arn])
  # S3 policy needs 2 resources, direct path and /*, this creates both.
  additional_list    = try([for k in var.config.additional_source_bucket_arn : concat([k], ["${k}/*"])], [])
  source_bucket_list = try(concat([var.config.source_bucket_arn, "${var.config.source_bucket_arn}/*"], flatten(local.additional_list)), [var.config.source_bucket_arn, "${var.config.source_bucket_arn}/*"])
}
