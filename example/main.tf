locals {
  args = {
    application = "my-application"
    services    = yamldecode(file("${path.module}/backing-services.yml"))
  }
  application = "my-application"
  environment = "my-environmennt"
  vpc_name    = "my-vpc"
}

module "backing-services-staging" {
  source = "../backing-services"

  args = local.args

  environment = "my-environment"
  vpc_name    = "my-vpc"
}

module "application-load-balancer" {
  source = "git::ssh://git@github.com/uktrade/terraform-platform-modules.git//application-load-balancer?depth=1&ref=main"

  application = local.application
  environment = local.environment
  vpc_name    = local.vpc_name

  config = {
    domains = [
      "my.domain.one",
      "my.domain.two"
    ]
  }
}

module "s3-bucket" {
  source = "git::ssh://git@github.com/uktrade/terraform-platform-modules.git//s3?depth=1&ref=main"

  application = local.application
  environment = local.environment
  vpc_name    = local.vpc_name

  config = {
    bucket_name = "${local.application}-${local.environment}-s3-bucket"
    versioning  = true
    objects     = []
  }
}

output "test" {
  value = module.backing-services-staging.test
}
