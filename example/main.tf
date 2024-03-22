locals {
  args = {
    application = "my-application"
    services    = yamldecode(file("${path.module}/backing-services.yml"))
  }
}

module "backing-services-staging" {
  source = "../backing-services"

  args = local.args

  environment = "my-environment"
  vpc_name    = "my-vpc"
}

module "application-load-balancer" {
  source = "git::ssh://git@github.com/uktrade/terraform-platform-modules.git//application-load-balancer?depth=1&ref=main"

  application = "my-application"
  environment = "my-environmennt"
  vpc_name    = "my-vpc"

  config = {
    domains = [
      "my.domain.one",
      "my.domain.two"
    ]
  }
}
