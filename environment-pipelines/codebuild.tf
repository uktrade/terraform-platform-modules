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

#------PROD-TARGET-ACCOUNT------
resource "aws_iam_role" "trigger_pipeline" {
  for_each           = local.set_of_triggering_pipeline_names
  name               = "${var.application}-${var.pipeline_name}-trigger-pipeline"
  assume_role_policy = data.aws_iam_policy_document.assume_trigger_pipeline.json
  tags               = local.tags
}

data "aws_iam_policy_document" "assume_trigger_pipeline" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy" "trigger_pipeline" {
  for_each = local.set_of_triggering_pipeline_names
  name     = "${var.application}-${var.pipeline_name}-trigger-pipeline"
  role     = aws_iam_role.trigger_pipeline[each.value].name
  policy   = data.aws_iam_policy_document.trigger_pipeline.json
}

data "aws_iam_policy_document" "trigger_pipeline" {
  statement {
    actions = [
      "codepipeline:StartPipelineExecution",
    ]
    resources = [
      "*",
    ]
  }
}

# NON PROD Assume role role
# resource "aws_iam_role" "assume_role_to_trigger_codepipeline" {
#   name               = "${var.application}-${var.pipeline_name}-assume-role-to-trigger-codepipeline"
#   assume_role_policy = data.aws_iam_policy_document.assume_codebuild_role.json
#   tags               = local.tags
# }

resource "aws_iam_role_policy" "assume_role_to_trigger_pipeline_policy" {
  for_each = toset(local.triggers_another_pipeline ? [""] : [])
  name     = "${var.application}-${var.pipeline_name}-assume-role-to-trigger-codepipeline-policy"
  role     = aws_iam_role.environment_pipeline_codebuild.name
  policy   = data.aws_iam_policy_document.assume_role_to_trigger_codepipeline_policy_document[""].json
}

data "aws_iam_policy_document" "assume_role_to_trigger_codepipeline_policy_document" {
  for_each = toset(local.triggers_another_pipeline ? [""] : [])
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    resources = [local.triggered_pipeline_account_role]
  }
}