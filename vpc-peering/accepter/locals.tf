# locals {
#   tags = {
#     managed-by = "DBT Platform - Terraform"
#     connection-name = var.arg_name
#     target-vpc = var.config.accepter_vpc_name
#     target-account = var.config.accepter_account_id
#   }
# }

locals {
  tags = {
    managed-by      = "DBT Platform - Terraform"
    connection-name = var.name
    source-vpc      = var.config.requester_vpc_name
  }
}
