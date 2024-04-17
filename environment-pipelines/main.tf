resource "aws_iam_role" "environment_pipeline_role" {
  name = "${var.application}-environment-pipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    application = "${var.application}"
    copilot-application = "${var.application}"
    managed-by = "DBT Platform - Terraform"
  }
}

module "artifact_store" {
  source = "../s3"

  application = var.application
  environment = "not-applicable"
  name = "${var.application}-environment-pipeline-artifact-store"

  config = {
    bucket_name = "${var.application}-environment-pipeline-artifact-store"
  }
}
