variable "application" {
  type = string
}

variable "all_codebases" {
  type = any
}

resource "aws_ecr_repository" "this" {
  for_each = var.all_codebases
  name     = "${var.application}/${each.key}"

  tags = {
    copilot-pipeline    = each.key
    copilot-application = var.application
  }

  image_scanning_configuration {
    scan_on_push = true
  }
}
