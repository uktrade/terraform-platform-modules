locals {
  tags = {
    application         = var.application
    copilot-application = var.application
    managed-by          = "DBT Platform - Terraform"
  }

  ecr_name          = "${var.application}/${var.config.name}"
  pipeline_branches = distinct([for pipeline in var.config.pipelines : pipeline.branch if lookup(pipeline, "branch", null) != null])
  tagged_pipeline   = length([for pipeline in var.config.pipelines : true if lookup(pipeline, "tag", null) == true]) > 0
}
