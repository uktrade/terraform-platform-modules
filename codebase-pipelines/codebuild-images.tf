data "aws_codestarconnections_connection" "github_codestar_connection" {
  name = var.application
}

resource "aws_codebuild_project" "codebase_image_build" {
  name          = "${var.application}-${var.codebase}-codebase-image-build"
  description   = "Publish images on push to ${var.repository}"
  build_timeout = 30
  service_role  = aws_iam_role.codebase_image_build.arn
  badge_enabled = true

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE"]
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "public.ecr.aws/uktrade/ci-image-builder:tag-latest"
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }

    environment_variable {
      name  = "ECR_REPOSITORY"
      value = local.ecr_name
    }

    environment_variable {
      name  = "CODESTAR_CONNECTION_ARN"
      value = data.aws_codestarconnections_connection.github_codestar_connection.arn
    }

    dynamic "environment_variable" {
      for_each = var.additional_ecr_repository != null ? [1] : []
      content {
        name  = "ADDITIONAL_ECR_REPOSITORY"
        value = var.additional_ecr_repository
      }
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.codebase_image_build.name
      stream_name = aws_cloudwatch_log_stream.codebase_image_build.name
    }
  }

  source {
    type            = "GITHUB"
    buildspec       = file("${path.module}/buildspec-images.yml")
    location        = "https://github.com/${var.repository}.git"
    git_clone_depth = 0
    git_submodules_config {
      fetch_submodules = false
    }
  }

  tags = local.tags
}

resource "aws_cloudwatch_log_group" "codebase_image_build" {
  # checkov:skip=CKV_AWS_338:Retains logs for 3 months instead of 1 year
  # checkov:skip=CKV_AWS_158:To be reworked
  name              = "codebuild/${var.application}-${var.codebase}-codebase-image-build/log-group"
  retention_in_days = 90
}

resource "aws_cloudwatch_log_stream" "codebase_image_build" {
  name           = "codebuild/${var.application}-${var.codebase}-codebase-image-build/log-stream"
  log_group_name = aws_cloudwatch_log_group.codebase_image_build.name
}

resource "aws_codebuild_webhook" "codebuild_webhook" {
  project_name = aws_codebuild_project.codebase_image_build.name
  build_type   = "BUILD"

  dynamic "filter_group" {
    for_each = local.pipeline_branches
    content {
      filter {
        type    = "EVENT"
        pattern = "PUSH"
      }

      filter {
        type    = "HEAD_REF"
        pattern = "^refs/heads/${filter_group.value}$"
      }
    }
  }

  dynamic "filter_group" {
    for_each = local.tagged_pipeline ? [1] : [0]
    content {
      filter {
        type    = "EVENT"
        pattern = "PUSH"
      }

      filter {
        type    = "HEAD_REF"
        pattern = "^refs/tags/.*"
      }
    }
  }
}
