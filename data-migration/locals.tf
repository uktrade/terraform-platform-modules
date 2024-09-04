locals {
  role_name   = "${substr(var.destination_bucket_identifier, 0, 48)}-S3MigrationRole"
  policy_name = "${substr(var.destination_bucket_identifier, 0, 46)}-S3MigrationPolicy"
}
