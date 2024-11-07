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
}
