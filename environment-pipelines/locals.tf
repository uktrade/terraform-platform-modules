locals {
  tags = {
    application         = var.application
    copilot-application = var.application
    managed-by          = "DBT Platform - Terraform"
  }

  stage_config = yamldecode(file("${path.module}/stage_config.yml"))

  initial_stages = flatten(
    [for env in var.environments : [
      {
        type : "plan",
        stage_name : "Plan-${env.name}",
        env : env.name,
        accounts : env.accounts,
        configuration : {
          ProjectName : "${var.application}-environment-pipeline-plan"
          PrimarySource : "build_output"
          EnvironmentVariables : jsonencode([{ name : "ENVIRONMENT", value : env.name }])
        }
      },
      coalesce(env.requires_approval, false) ? [{
        type : "approve",
        stage_name : "Approve-${env.name}",
        env : ""
        configuration : {
          CustomData : "Review Terraform Plan"
          ExternalEntityLink : "https://${data.aws_region.current.name}.console.aws.amazon.com/codesuite/codebuild/${data.aws_caller_identity.current.account_id}/projects/${var.application}-environment-pipeline-tf-plan/build/#{tf-plan.BUILD_ID}"
        },
        namespace : null
      }] : [],
      {
        type : "apply",
        env : env.name,
        stage_name : "Apply-${env.name}",
        accounts : env.accounts,
        configuration : {
          ProjectName : "${var.application}-environment-pipeline-apply"
          PrimarySource : "build_output"
          EnvironmentVariables : jsonencode([{ name : "ENVIRONMENT", value : env.name }])
        },
        namespace : null
      }
      ]
  ])

  dns_ids     = tolist(toset(flatten([for stage in local.initial_stages : lookup(stage, "accounts", null) != null ? [stage.accounts.dns.id] : []])))
  dns_entries = [for id in local.dns_ids : "arn:aws:iam::${id}:role/sandbox-codebuild-assume-role"]

  stages = [for stage in local.initial_stages : merge(stage, local.stage_config[stage["type"]])]

  central_log_destination_arn = "arn:aws:logs:eu-west-2:812359060647:destination:cwl_log_destination"
}
