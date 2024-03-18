locals {
    plans = yamldecode(file("${path.module}/plans.yml"))

    // select environment for each service and expand config from "*"
    services_select_env = { for k, v in var.services : k => merge(v, merge(lookup(v.environments, "*", {}), lookup(v.environments, var.environment, {}))) }

    // expand plan config
    services_expand_plan = { for k, v in local.services_select_env : k => merge(lookup(local.plans[v.type], lookup(v, "plan", "NO-PLAN"), {}), v) }

    // remove unnecessary fields
    services = {
        for service_name, service_config in local.services_expand_plan : 
            service_name => {
                for k, v in service_config : k => v if !contains(["environments", "services"], k)
            }
    }

    // filter services per backing-service type
    postgres = { for k, v in local.services : k => v if v.type == "postgres" }
    s3 = { for k, v in local.services : k => v if v.type == "s3" }
    redis = { for k, v in local.services : k => v if v.type == "redis" }
    opensearch = { for k, v in local.services : k => v if v.type == "opensearch" }
    monitoring = { for k, v in local.services : k => v if v.type == "monitoring" }

    vpc = lookup(var.environments["vpc-environment-map"], var.environment, var.environments["vpc-environment-map"]["*"]).vpc
}

### DEBUG
output "services" {
    value = local.services
}

