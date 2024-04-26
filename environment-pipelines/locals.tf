locals {
  tags = {
    application         = var.application
    copilot-application = var.application
    managed-by          = "DBT Platform - Terraform"
  }

  stage_config = yamldecode(file("${path.module}/stage_config.yml"))

#  environment = [
#    {
#      name = dev
#    },
#    {
#      name = prod
#      requires_approval = true
#    }
#  ]
#
#  [{plan stuff in here}, {approval: true} , []]
#
#
#[[{plan stuff in here}, [], []], [{plan stuff in here}, [], []]]
#        flatten(^^)


  stages = [
    {
      type = "plan"
      env = "dev",
      approval = false
    },
#    {
#      type = "approve"
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
