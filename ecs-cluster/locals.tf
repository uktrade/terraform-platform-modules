locals {
  tags = {
    application = var.application
    environment = var.environment
    managed-by  = "DBT Platform - Terraform"
  }

  region_account = "${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}"
  cluster_name   = "${var.application}-${var.environment}-tf"

  is_production_env = contains(["prod", "production", "PROD", "PRODUCTION"], var.environment)
  log_destination_arn = local.is_production_env ? "arn:aws:logs:eu-west-2:812359060647:destination:cwl_log_destination" : "arn:aws:logs:eu-west-2:812359060647:destination:platform-logging-logstash-distributor-non-production"

  bucket_access_services = toset(flatten([
    for bucket_key, bucket_config in var.s3_config :
    [for service in bucket_config.services :
      service if contains(keys(var.services), service)
    ]
  ]))

  web_services = {
    for service_name, service_config in var.services :
    service_name => service_config
    if service_config.type == "web"
  }

# Sample value of local.web_services above
  # {
  #   "api" = {
  #     type = "web"
  #     hostnames = ["api.dev.demodjango.uktrade.digital"]
  #     path_patterns = ["/*"]
  #   },
  #   "web" = {
  #     type = "web"
  #     hostnames = ["web.dev.demodjango.uktrade.digital"]
  #     path_patterns = ["/", "/test"]
  #   }
  # }

  listener_rules_config = {
    for service_name, service_config in local.web_services :
    service_name => {
      service = service_name
      host    = lookup(service_config, "hostnames", ["${service_name}.${var.environment}.${var.application}.uktrade.digital"])
      path    = lookup(service_config, "path_patterns", ["/*"])
      is_root = alltrue([for path in lookup(service_config, "path_patterns", ["/*"]) : (path == "/" || path == "/*")])
    }
  }

# Sample value of local.listener_rules_config above
# {
#   "api" = {
#     service = "api"
#     host = ["api.dev.demodjango.uktrade.digital"]
#     path = ["/*"]
#     is_root = true
#   },
#   "web" = {
#     service = "web"
#     host = ["web.dev.demodjango.uktrade.digital"]
#     path = ["/", "/test"]
#     is_root = false
#   }
# }

  root_rules_list = [
    for service_name, service_config in local.listener_rules_config :
    service_config
    if service_config.is_root == true
  ]

  non_root_rules_list = [
    for service_name, service_config in local.listener_rules_config :
    service_config
    if service_config.is_root == false
  ]

  combined_rules_list = concat(local.non_root_rules_list, local.root_rules_list)

  rules_with_priority = {
    for index, service_config in local.combined_rules_list :
    service_config.service => merge(service_config, { priority = 30000 + (index * 100) })
  }
}
