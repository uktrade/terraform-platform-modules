mock_provider "aws" {}

override_data {
  target = data.aws_iam_policy_document.assume_role
  values = {
    json = "{}"
  }
}

override_data {
  target = data.aws_iam_policy_document.assume_environment_codebuild_role
  values = {
    json = "{}"
  }
}

variables {
  expected_tags = {
    application         = "my-app"
    copilot-application = "my-app"
    managed-by          = "DBT Platform - Terraform"
  }
}

run "test_create_pipelines" {
  command = plan

  variables {
    application = "my-app"
    repository  = "my-repository"
  }

  # IAM Role for the pipeline.
  assert {
    condition     = aws_iam_role.environment_pipeline_role.name == "my-app-environment-pipeline-role"
    error_message = "Invalid value for aws_iam_role.environment_pipeline_role.name parameter, should be: 'my-app-environment-pipeline-role'"
  }

  assert {
    condition     = jsonencode(aws_iam_role.environment_pipeline_role.tags) == jsonencode(var.expected_tags)
    error_message = "Invalid value for aws_iam_role.environment_pipeline_role.tags parameter, should be: ${jsonencode(var.expected_tags)}"
  }

  # S3 artifact-store bucket.
  assert {
    condition     = module.artifact_store.bucket_name == "my-app-environment-pipeline-artifact-store"
    error_message = "Invalid name for aws_s3_bucket"
  }
}

run "test_create_pipelines_with_different_application" {
  command = plan

  variables {
    application = "my-other-app"
    repository  = "my-repository"
  }

  assert {
    condition     = aws_iam_role.environment_pipeline_role.name == "my-other-app-environment-pipeline-role"
    error_message = "Invalid value for aws_iam_role.environment_pipeline_role.name parameter, should be: 'my-other-app-environment-pipeline-role'"
  }

  assert {
    condition     = aws_iam_role.environment_pipeline_role.tags.application == "my-other-app"
    error_message = "Invalid value for aws_iam_role.environment_pipeline_role.tags.application parameter, should be: 'my-other-app'"
  }

  assert {
    condition     = aws_iam_role.environment_pipeline_role.tags.copilot-application == "my-other-app"
    error_message = "Invalid value for aws_iam_role.environment_pipeline_role.tags.copilot-application parameter, should be: 'my-other-app'"
  }

  assert {
    condition     = aws_iam_role.environment_pipeline_role.tags.managed-by == "DBT Platform - Terraform"
    error_message = "Invalid value for aws_iam_role.environment_pipeline_role.tags.managed-by parameter, should be: 'DBT Platform - Terraform'"
  }
}
