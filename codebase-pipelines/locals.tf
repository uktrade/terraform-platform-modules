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

  pipeline_map = { for id, val in var.pipelines : id => val }

  #   ["web","api","celery-worker","celery-beat"]
  services = sort(flatten([
    for run_group in var.services : [for service in flatten(values(run_group)) : service]
  ]))

  service_export_names = sort(flatten([
    for run_group in var.services : [for service in flatten(values(run_group)) : upper(replace(service, "-", "_"))]
  ]))

  #   [{"name":"web","order":1},{"name":"api","order":2},{"name":"celery-beat","order":2},{"name":"celery-worker","order":2}]
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
