locals {
  args = {
    application = "intranet"
    services    = yamldecode(file("${path.module}/backing-services.yml"))
  }
}

module "backing-services-staging" {
  source = "../backing-services"

  args = local.args

  environment = "staging"
  vpc_name    = "intranet-nonprod"
}
