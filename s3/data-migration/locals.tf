locals {
  role_name   = "${substr(var.destination_bucket_identifier, 0, 48)}-S3DataMigration"
  policy_name = "${substr(var.destination_bucket_identifier, 0, 49)}-ExternalImport"
}