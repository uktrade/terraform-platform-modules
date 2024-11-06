variable "pipeline_name" {
  type = string
}

variable "application" {
  type = string
}

locals {
  ecr_names = {
    (var.pipeline_name) = "${var.application}/${var.pipeline_name}"
  }
}

import {
  for_each = local.ecr_names
  to       = aws_ecr_repository.this[each.key]
  id       = each.value
}

resource "aws_ecr_repository" "this" {
  for_each = local.ecr_names
  name     = each.value

  tags = {
    copilot-pipeline    = each.key
    copilot-application = "demodjango"
  }

  image_scanning_configuration {
    scan_on_push = true
  }
}
