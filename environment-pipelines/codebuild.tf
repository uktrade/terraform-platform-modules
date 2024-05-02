resource "aws_codebuild_project" "environment_pipeline" {
  name          = "${var.application}-environment-pipeline"
  description   = "Provisions the ${var.application} application's extensions."
  build_timeout = 5
  service_role  = aws_iam_role.environment_pipeline_codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type     = "S3"
    location = module.artifact_store.bucket_name
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.environment_pipeline_codebuild.name
      stream_name = aws_cloudwatch_log_stream.environment_pipeline_codebuild.name
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = file("${path.module}/buildspec.yml")
  }

  tags = local.tags
}

resource "aws_cloudwatch_log_group" "environment_pipeline_codebuild" {
  name = "codebuild/${var.application}-environment-terraform/log-group"
  # checkov:skip=CKV_AWS_338:Retains logs for 3 months instead of 1 year
  retention_in_days = 90
}

resource "aws_cloudwatch_log_stream" "environment_pipeline_codebuild" {
  name           = "codebuild/${var.application}-environment-terraform/log-stream"
  log_group_name = aws_cloudwatch_log_group.environment_pipeline_codebuild.name
}

# Terraform plan
resource "aws_codebuild_project" "environment_pipeline_tf_plan" {
  name          = "${var.application}-environment-pipeline-tf-plan"
  description   = "Provisions the ${var.application} application's extensions."
  build_timeout = 5
  service_role  = aws_iam_role.environment_pipeline_codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type     = "S3"
    location = module.artifact_store.bucket_name
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.environment_pipeline_codebuild.name
      stream_name = aws_cloudwatch_log_stream.environment_pipeline_codebuild.name
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = file("${path.module}/buildspec-plan.yml")
  }

  tags = local.tags
}
