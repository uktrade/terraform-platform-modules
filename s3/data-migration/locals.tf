locals {
  role_name = "${substr(var.destination_bucket_name, 0, 49)}-ExternalImport"
}