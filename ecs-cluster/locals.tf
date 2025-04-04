locals {
  tags = {
    application = var.application
    environment = var.environment
    managed-by  = "DBT Platform - Terraform"
  }

  region_account = "${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}"
  cluster_name   = "${var.application}-${var.environment}-tf"

  bucket_access_services = toset(flatten([
    for bucket_key, bucket_config in var.s3_config :
    [for service in bucket_config.services :
      service if contains(keys(var.services), service)
    ]
  ]))

  web_services = {
    for service_name, service_config in var.services :
    service_name => service_config
    if service_config.type == "web" && contains(keys(service_config), "alb")
  }
}
