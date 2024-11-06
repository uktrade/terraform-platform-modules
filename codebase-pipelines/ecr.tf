resource "aws_ecr_repository" "this" {
  name = local.ecr_name

  tags = {
    copilot-pipeline    = var.config.name
    copilot-application = var.application
  }

  image_scanning_configuration {
    scan_on_push = true
  }
}
