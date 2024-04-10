# locals {
#   tags = {
#     managed-by = "DBT Platform - Terraform"
#     connection-name = var.arg_name
#     source-vpc = var.arg_config.source_vpc_name
#   }
# }

locals {
  tags = {
    managed-by      = "DBT Platform - Terraform"
    connection-name = var.name
    target-vpc      = var.config.accepter_vpc_name
    target-account  = var.config.accepter_account_id
  }
}
