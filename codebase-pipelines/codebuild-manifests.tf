resource "aws_codebuild_project" "codebase_deploy_manifests" {
  for_each       = local.pipeline_map
  name           = "${var.application}-${var.codebase}-${each.value.name}-codebase-deploy-manifests"
  description    = "Create image deploy manifests to deploy services"
  build_timeout  = 5
  service_role   = aws_iam_role.codebuild_manifests.arn
  encryption_key = aws_kms_key.artifact_store_kms_key.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type     = "S3"
    location = aws_s3_bucket.artifact_store.bucket
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.codebase_deploy_manifests.name
      stream_name = aws_cloudwatch_log_stream.codebase_deploy_manifests.name
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = templatefile("${path.module}/buildspec-manifests.yml", { application = var.application, environments = [for env in each.value.environments : upper(env.name)], services = local.service_export_names })
  }

  tags = local.tags
}

resource "aws_kms_key" "codebuild_kms_key" {
  description         = "KMS Key for ${var.application}-${var.codebase} CodeBuild encryption"
  enable_key_rotation = true

  policy = jsonencode({
    Id = "key-default-1"
    Statement = [
      {
        "Sid" : "Enable IAM User Permissions",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        "Action" : "kms:*",
        "Resource" : "*"
      }
    ]
    Version = "2012-10-17"
  })

  tags = local.tags
}

resource "aws_cloudwatch_log_group" "codebase_deploy_manifests" {
  # checkov:skip=CKV_AWS_338:Retains logs for 3 months instead of 1 year
  # checkov:skip=CKV_AWS_158: To be reworked
  name              = "codebuild/${var.application}-${var.codebase}-codebase-deploy-manifests/log-group"
  retention_in_days = 90
}

resource "aws_cloudwatch_log_stream" "codebase_deploy_manifests" {
  name           = "codebuild/${var.application}-${var.codebase}-codebase-deploy-manifests/log-stream"
  log_group_name = aws_cloudwatch_log_group.codebase_deploy_manifests.name
}
