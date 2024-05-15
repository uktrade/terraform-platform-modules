locals {
  args = {
    application    = "my-application"
    services       = yamldecode(file("${path.module}/extensions.yml"))
    dns_account_id = one([for env in yamldecode(file("${path.module}/pipelines.yml"))["environments"] : env if env["name"] == "my-environment"])["accounts"]["dns"]["id"]
  }
}

module "extensions-staging" {
  source      = "../extensions"
  args        = local.args
  environment = "my-environment"
  vpc_name    = "my-vpc"
}
