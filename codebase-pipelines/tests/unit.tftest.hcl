mock_provider "aws" {}

override_data {
  target = data.aws_iam_policy_document.assume_codebuild_role
  values = {
    json = "{\"Sid\": \"AssumeCodebuildRole\"}"
  }
}

override_data {
  target = data.aws_iam_policy_document.codebuild_logs
  values = {
    json = "{\"Sid\": \"CodeBuildLogs\"}"
  }
}

override_data {
  target = data.aws_iam_policy_document.ecr_access
  values = {
    json = "{\"Sid\": \"ECRAccess\"}"
  }
}

override_data {
  target = data.aws_iam_policy_document.codestar_connection_access
  values = {
    json = "{\"Sid\": \"CodeStarConnectionAccess\"}"
  }
}

variables {
  application               = "my-app"
  codebase                  = "my-codebase"
  repository                = "my-repository"
  additional_ecr_repository = "my-additional-repository"
  expected_tags = {
    application         = "my-app"
    copilot-application = "my-app"
    managed-by          = "DBT Platform - Terraform"
  }
  pipelines = [
    {
      name   = "main",
      branch = "main",
      environments = [
        { name = "dev" }
      ]
    },
    {
      name = "tagged",
      tag  = true,
      environments = [
        { name = "staging" },
        { name = "prod", requires_approval = true }
      ]
    }
  ]
}

run "test_codebuild" {
  command = plan

  assert {
    condition     = aws_codebuild_project.codebase_image_build.name == "my-app-my-codebase-codebase-image-build"
    error_message = "Should be: my-app-my-codebase-codebase-image-build"
  }
  assert {
    condition     = aws_codebuild_project.codebase_image_build.description == "Publish images on push to my-repository"
    error_message = "Should be: 'Publish images on push to my-repository'"
  }
  assert {
    condition     = aws_codebuild_project.codebase_image_build.build_timeout == 30
    error_message = "Should be: 30"
  }
  assert {
    condition     = one(aws_codebuild_project.codebase_image_build.artifacts).type == "NO_ARTIFACTS"
    error_message = "Should be: 'NO_ARTIFACTS'"
  }
  assert {
    condition     = one(aws_codebuild_project.codebase_image_build.cache).type == "LOCAL"
    error_message = "Should be: 'LOCAL'"
  }
  assert {
    condition     = one(aws_codebuild_project.codebase_image_build.cache).location == "LOCAL_DOCKER_LAYER_CACHE"
    error_message = "Should be: 'LOCAL_DOCKER_LAYER_CACHE'"
  }
  assert {
    condition     = one(aws_codebuild_project.codebase_image_build.environment).compute_type == "BUILD_GENERAL1_SMALL"
    error_message = "Should be: 'BUILD_GENERAL1_SMALL'"
  }
  assert {
    condition     = one(aws_codebuild_project.codebase_image_build.environment).image == "public.ecr.aws/uktrade/ci-image-builder:tag-latest"
    error_message = "Should be: 'public.ecr.aws/uktrade/ci-image-builder:tag-latest'"
  }
  assert {
    condition     = one(aws_codebuild_project.codebase_image_build.environment).type == "LINUX_CONTAINER"
    error_message = "Should be: 'LINUX_CONTAINER'"
  }
  assert {
    condition     = one(aws_codebuild_project.codebase_image_build.environment).privileged_mode == true
    error_message = "Should be: true"
  }
  assert {
    condition = aws_codebuild_project.codebase_image_build.logs_config[0].cloudwatch_logs[
    0
    ].group_name == "codebuild/my-app-my-codebase-codebase-image-build/log-group"
    error_message = "Should be: 'codebuild/my-app-my-codebase-codebase-image-build/log-group'"
  }
  assert {
    condition = aws_codebuild_project.codebase_image_build.logs_config[0].cloudwatch_logs[
    0
    ].stream_name == "codebuild/my-app-my-codebase-codebase-image-build/log-stream"
    error_message = "Should be: 'codebuild/my-app-my-codebase-codebase-image-build/log-stream'"
  }
  assert {
    condition     = one(aws_codebuild_project.codebase_image_build.source).type == "GITHUB"
    error_message = "Should be: 'GITHUB'"
  }
  assert {
    condition     = one(aws_codebuild_project.codebase_image_build.source).location == "https://github.com/my-repository.git"
    error_message = "Should be: 'https://github.com/my-repository.git'"
  }
  assert {
    condition     = length(regexall(".*/work/cli build.*", aws_codebuild_project.codebase_image_build.source[0].buildspec)) > 0
    error_message = "Should contain: '/work/cli build'"
  }
  assert {
    condition     = jsonencode(aws_codebuild_project.codebase_image_build.tags) == jsonencode(var.expected_tags)
    error_message = "Should be: ${jsonencode(var.expected_tags)}"
  }

  # Cloudwatch config:
  assert {
    condition     = aws_cloudwatch_log_group.codebase_image_build.name == "codebuild/my-app-my-codebase-codebase-image-build/log-group"
    error_message = "Should be: 'codebuild/my-app-my-codebase-codebase-image-build/log-group'"
  }
  assert {
    condition     = aws_cloudwatch_log_group.codebase_image_build.retention_in_days == 90
    error_message = "Should be: 90"
  }
  assert {
    condition     = aws_cloudwatch_log_stream.codebase_image_build.name == "codebuild/my-app-my-codebase-codebase-image-build/log-stream"
    error_message = "Should be: 'codebuild/my-app-my-codebase-codebase-image-build/log-stream'"
  }
  assert {
    condition     = aws_cloudwatch_log_stream.codebase_image_build.log_group_name == "codebuild/my-app-my-codebase-codebase-image-build/log-group"
    error_message = "Should be: 'codebuild/my-app-my-codebase-codebase-image-build/log-group'"
  }

  # Webhook config:
  assert {
    condition     = aws_codebuild_webhook.codebuild_webhook.project_name == "my-app-my-codebase-codebase-image-build"
    error_message = "Should be: 'my-app-my-codebase-codebase-image-build'"
  }
}
