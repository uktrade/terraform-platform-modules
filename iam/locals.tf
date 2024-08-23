locals {
  role_name = "${substr(var.resource_name, 0, 49)}-ExternalAccess"
}