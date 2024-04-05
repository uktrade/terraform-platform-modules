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
