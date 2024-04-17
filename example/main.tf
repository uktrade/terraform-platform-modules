locals {
  args = {
    application = "my-application"
    services    = yamldecode(file("${path.module}/extensions.yml"))
  }
}

module "extensions-staging" {
  source      = "../extensions"
  args        = local.args
  environment = "my-environment"
  vpc_name    = "my-vpc"
  providers = {
    aws.domain = aws.domain
  }
}
