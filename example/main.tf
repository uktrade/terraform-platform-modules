locals {
  args = {
    application = "my-application"
    services    = yamldecode(file("${path.module}/extensions.yml"))
  }
}

module "extensions-staging" {
  source = "../extensions"
  providers = {
    aws.domain = aws.domain
  }

  args = local.args

  environment = "my-environment"
  vpc_name    = "my-vpc"
}
