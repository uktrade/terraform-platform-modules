locals {
  role_name = "${substr(var.bucket_name, 0, 49)}-ExternalImport"
}