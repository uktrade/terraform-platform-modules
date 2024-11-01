locals {
  plans = yamldecode(file("${path.module}/plans.yml"))

  # So we don't hit a Parameter Store limit, filter environment config for extensions so it only includes the defaults (`"*"`) and the current environment
  extensions_for_environment = {
    for k, v in var.args.services :
    k => merge(v, {
      environments = {
        for ek, ev in v["environments"] :
        ek => ev if contains(["*", var.environment], ek)
      }
    })
  }

  // select environment for each service and expand config from "*"
  services_select_env = { for k, v in var.args.services : k => merge(v, merge(lookup(v.environments, "*", {}), lookup(v.environments, var.environment, {}))) }

  // expand plan config
  services_expand_plan = { for k, v in local.services_select_env : k => merge(lookup(local.plans[v.type], lookup(v, "plan", "NO-PLAN"), {}), v) }

  // remove unnecessary fields
  services = {
    for service_name, service_config in local.services_expand_plan :
    service_name => {
      for k, v in service_config : k => v if !contains(["environments", "services", "plan"], k)
    }
  }

  // filter services per extension type
  postgres   = { for k, v in local.services : k => v if v.type == "postgres" }
  s3         = { for k, v in local.services : k => v if v.type == "s3" }
  redis      = { for k, v in local.services : k => v if v.type == "redis" }
  opensearch = { for k, v in local.services : k => v if v.type == "opensearch" }
  monitoring = { for k, v in local.services : k => v if v.type == "monitoring" }
  alb        = { for k, v in local.services : k => v if v.type == "alb" }
  cdn        = { for k, v in local.services : k => v if v.type == "alb" }

  tags = {
    application         = var.args.application
    environment         = var.environment
    managed-by          = "DBT Platform - Terraform"
    copilot-application = var.args.application
    copilot-environment = var.environment
  }
}
