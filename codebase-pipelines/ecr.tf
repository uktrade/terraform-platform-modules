# variable "pipeline_name" {
#   type = string
# }
# 
variable "application" {
  type = string
}
# 
# locals {
#   ecr_names = {
#     (var.pipeline_name) = "${var.application}/${var.pipeline_name}"
#   }
# }
# 
# import {
#   for_each = local.ecr_names
#   to       = aws_ecr_repository.this[each.key]
#   id       = each.value
# }

variable "ecr_names" {
  type = map(string)
}

variable "all_codebases" {
  type = any
}

variable "additional_ecr_repository" {
  type = string
}

variable "repository" {
  type = string
}

variable "codebase_name" {
  type = string
}

resource "aws_ecr_repository" "this" {
  for_each = var.ecr_names
  name     = each.value

  tags = {
    copilot-pipeline    = each.key
    copilot-application = "demodjango"
  }

  image_scanning_configuration {
    scan_on_push = true
  }
}

#resource "aws_ecr_repository" "some_ecr_repo" {
#  name     = "demodjango/application"
#}
