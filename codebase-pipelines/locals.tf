locals {
  tags = {
    application         = var.application
    copilot-application = var.application
    managed-by          = "DBT Platform - Terraform"
  }

  account_region = "${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}"

  ecr_name                 = "${var.application}/${var.codebase}"
  prefixed_repository_name = "uktrade/${var.application}"
  repository_url           = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${local.ecr_name}"

  pipeline_branches = distinct([
    for pipeline in var.pipelines : pipeline.branch if lookup(pipeline, "branch", null) != null
  ])

  tagged_pipeline = length([for pipeline in var.pipelines : true if lookup(pipeline, "tag", null) == true]) > 0

  base_env_config = {
    for name, config in var.env_config : name => {
      account : lookup(lookup(lookup(merge(lookup(var.env_config, "*", {}), config), "accounts", {}), "deploy", {}), "id", {})
    } if name != "*"
  }

  deploy_account_ids = distinct([for env in local.base_env_config : env.account])

  pipeline_map = {
    for id, val in var.pipelines : id => merge(val, {
      environments : [
        for name, env in val.environments : merge(env, lookup(local.base_env_config, env.name, {}))
      ]
    })
  }

  pipeline_environments = distinct(flatten([
    for pipeline in local.pipeline_map : [for env in pipeline.environments : env]
  ]))

  services = sort(flatten([
    for run_group in var.services : [for service in flatten(values(run_group)) : service]
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

  pipeline_names = flatten(concat([for pipeline in local.pipeline_map :
    "${var.application}-${var.codebase}-${pipeline.name}-codebase-pipeline"],
    ["${var.application}-${var.codebase}-manual-release-pipeline"]
  ))
}
