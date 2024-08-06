resource "aws_codebuild_project" "environment_pipeline_build" {
  name           = "${var.application}-${var.pipeline_name}-environment-pipeline-build"
  description    = "Provisions the ${var.application} application's extensions."
  build_timeout  = 5
  service_role   = aws_iam_role.environment_pipeline_codebuild.arn
  encryption_key = module.artifact_store.kms_key_arn

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
    buildspec = file("${path.module}/buildspec-install-build-tools.yml")
  }

  tags = local.tags
}

resource "aws_cloudwatch_log_group" "environment_pipeline_codebuild" {
  name = "codebuild/${var.application}-${var.pipeline_name}-environment-terraform/log-group"
  # checkov:skip=CKV_AWS_338:Retains logs for 3 months instead of 1 year
  retention_in_days = 90
}

resource "aws_cloudwatch_log_stream" "environment_pipeline_codebuild" {
  name           = "codebuild/${var.application}-${var.pipeline_name}-environment-terraform/log-stream"
  log_group_name = aws_cloudwatch_log_group.environment_pipeline_codebuild.name
}

# Terraform plan
resource "aws_codebuild_project" "environment_pipeline_plan" {
  name           = "${var.application}-${var.pipeline_name}-environment-pipeline-plan"
  description    = "Provisions the ${var.application} application's extensions."
  build_timeout  = 5
  service_role   = aws_iam_role.environment_pipeline_codebuild.arn
  encryption_key = module.artifact_store.kms_key_arn

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

# Terraform apply
resource "aws_codebuild_project" "environment_pipeline_apply" {
  name           = "${var.application}-${var.pipeline_name}-environment-pipeline-apply"
  description    = "Provisions the ${var.application} application's extensions."
  build_timeout  = 120
  service_role   = aws_iam_role.environment_pipeline_codebuild.arn
  encryption_key = module.artifact_store.kms_key_arn

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
    buildspec = file("${path.module}/buildspec-apply.yml")
  }

  tags = local.tags
}

# Terraform trigger
resource "aws_codebuild_project" "trigger_other_environment_pipeline" {
  name           = "${var.application}-${var.pipeline_name}-environment-pipeline-trigger"
  description    = "Triggers a target pipeline"
  build_timeout  = 5
  service_role   = aws_iam_role.environment_pipeline_codebuild.arn
  encryption_key = module.artifact_store.kms_key_arn

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
    buildspec = file("${path.module}/buildspec-trigger.yml")
  }

  tags = local.tags
}
