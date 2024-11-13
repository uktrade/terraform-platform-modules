locals {
  tags = {
    application         = var.application
    copilot-application = var.application
    managed-by          = "DBT Platform - Terraform"
  }

  account_region = "${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}"

  ecr_name = "${var.application}/${var.codebase}"
  pipeline_branches = distinct([
    for pipeline in var.pipelines : pipeline.branch if lookup(pipeline, "branch", null) != null
  ])
  tagged_pipeline = length([for pipeline in var.pipelines : true if lookup(pipeline, "tag", null) == true]) > 0

  base_env_config = {
    for name, config in var.environments : name => merge(lookup(var.environments, "*", {}), config) if name != "*"
  }

  # Adds accounts map to each environment within each pipeline
  pipeline_environment_account_map = {
    for id, val in var.pipelines : id => {
      "trigger_prod" : length([
        for name, env in val.environments : true
        if lookup(local.base_env_config, env.name, {}).accounts.deploy.name != var.deploy_account
      ]) > 0,
      "environments" : [
        for name, env in val.environments : merge(env, {
          "account" : lookup(local.base_env_config, env.name, {}).accounts.deploy
        }) if lookup(local.base_env_config, env.name, {}).accounts.deploy.name == var.deploy_account
      ]
    }
  }

  # Pipeline map should only include pipelines that deploy to the current deploy account
  pipeline_map = {
    for id, val in var.pipelines : id => merge(val, local.pipeline_environment_account_map[id])
    if length(local.pipeline_environment_account_map[id].environments) > 0
  }

  pipeline_environments = flatten([for pipeline in local.pipeline_map : [for env in pipeline.environments : env.name]])

  services = sort(flatten([
    for run_group in var.services : [for service in flatten(values(run_group)) : service]
  ]))

  service_export_names = sort(flatten([
    for run_group in var.services : [for service in flatten(values(run_group)) : upper(replace(service, "-", "_"))]
  ]))

  service_order_list = flatten([
    for index, group in var.services : [
      for key, services in group : [
        for sorted_service in local.services : [
          for service in services : {
            name  = service
            order = index + 1
          } if service == sorted_service
        ]
      ]
    ]
  ])
}
