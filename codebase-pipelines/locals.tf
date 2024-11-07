locals {
  tags = {
    application         = var.application
    copilot-application = var.application
    managed-by          = "DBT Platform - Terraform"
  }

  account_region = "${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}"

  ecr_name          = "${var.application}/${var.codebase}"
  pipeline_branches = distinct([for pipeline in var.pipelines : pipeline.branch if lookup(pipeline, "branch", null) != null])
  tagged_pipeline   = length([for pipeline in var.pipelines : true if lookup(pipeline, "tag", null) == true]) > 0
}
