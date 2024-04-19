resource "aws_codebuild_project" "environment_terraform" {
  name     = "${var.application}-environment-terraform"
  description   = "Runs the ${var.application} application's extensions terraform."
  build_timeout = 5
  service_role  = aws_iam_role.environment_codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type     = "S3"
    location = module.artifact_store.bucket_name
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

#    environment_variable {
#      name  = "SOME_KEY1"
#      value = "SOME_VALUE1"
#    }
#
#    environment_variable {
#      name  = "SOME_KEY2"
#      value = "SOME_VALUE2"
#      type  = "PARAMETER_STORE"
#    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.environment_terraform_codebuild.name
      stream_name = aws_cloudwatch_log_stream.environment_terraform_codebuild.name
    }
  }

  source {
    type            = "CODEPIPELINE"
    buildspec       = file("${path.module}/buildspec.yml")
  }

#  source_version = "main"
#
#  vpc_config {
#    vpc_id = aws_vpc.example.id
#
#    subnets = [
#      aws_subnet.example1.id,
#      aws_subnet.example2.id,
#    ]
#
#    security_group_ids = [
#      aws_security_group.example1.id,
#      aws_security_group.example2.id,
#    ]
#  }

  tags = local.tags
}

resource "aws_cloudwatch_log_group" "environment_terraform_codebuild" {
  name           = "codebuild/${var.application}-environment-terraform/log-group"
  # checkov:skip=CKV_AWS_338:Retains logs for 3 months instead of 1 year
  retention_in_days = 90
}

resource "aws_cloudwatch_log_stream" "environment_terraform_codebuild" {
  name           = "codebuild/${var.application}-environment-terraform/log-stream"
  log_group_name = aws_cloudwatch_log_group.environment_terraform_codebuild.name
}
