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
        env : env.name, accounts : env.accounts
      },
      coalesce(env.requires_approval, false) ? [{ type : "approve", stage_name : "Approve-${env.name}", env : "" }] : [],
      {
        type : "apply",
        env : env.name,
        stage_name : "Apply-${env.name}",
      accounts : env.accounts }
      ]
  ])

  dns_ids     = tolist(toset(flatten([for stage in local.initial_stages : lookup(stage, "accounts", null) != null ? [stage.accounts.dns.id] : []])))
  dns_entries = [for id in local.dns_ids : "arn:aws:iam::${id}:role/sandbox-codebuild-assume-role"]

  stages = [for stage in local.initial_stages : merge(stage, local.stage_config[stage["type"]])]
}