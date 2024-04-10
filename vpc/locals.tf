locals {
  vpc_cidr_mask    = ".0.0/16"
  subnet_cidr_mask = ".0/24"
  region           = "eu-west-2"
  tags = {
    managed-by = "DBT Platform - Terraform"
  }
}
