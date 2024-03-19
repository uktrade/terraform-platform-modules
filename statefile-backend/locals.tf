locals {
  tags = {
    Name       = var.aws_account_name
    managed-by = "Terraform"
  }
}
