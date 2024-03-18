locals {
    application = "intranet"
    services = yamldecode(file("${path.module}/backing-services.yml"))
    environments = yamldecode(file("${path.module}/environments.yml"))
}

module "backing-services-staging" {
    source = "../backing-services"

    application = local.application
    services = local.services
    environments = local.environments

    environment = "staging"
}

module "backing-services-dev" {
    source = "../backing-services"

    application = local.application
    services = local.services
    environments = local.environments

    environment = "dev"
}

module "backing-services-uat" {
    source = "../backing-services"

    application = local.application
    services = local.services
    environments = local.environments

    environment = "uat"
}

### DEBUG
output "test1" {
  value = module.backing-services-staging.services
}

