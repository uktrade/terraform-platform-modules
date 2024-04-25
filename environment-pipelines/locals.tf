locals {
  tags = {
    application         = var.application
    copilot-application = var.application
    managed-by          = "DBT Platform - Terraform"
  }

  stage_config = yamldecode(file("${path.module}/stage_config.yml"))

  stages = [
    {
      type = "plan"
      env = "dev",
      approval = false
    },
#    {
#      type = "plan"
#      env = "prod",
#      approval = false
#    },
#    {
#      type = "approve"
#      env = "prod",
#      approval = false
#    },
  ]


}
