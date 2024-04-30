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


  stages = [for env in var.environments : { type: "plan", env: env.name, approval: env.requires_approval, accounts: env.accounts }]


#  stages = [
#    {
#      type = "plan"
#      env = "dev",
#      approval = false,
#      accounts = {
#        deploy = {
#          name = "sandbox",
#          id = "852676506468"
#        },
#        dns = {
#          name = "dev",
#          id = "011755346992"
#        }
#      }
#    },
##    {
##      type = "approve"
##      env = "prod",
##      approval = false
##    },
##    {
##      type = "approve"
##      env = "prod",
##      approval = false
##    },
#  ]

}
