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

run "test_create_pipeline" {
  command = plan

  variables {
    application = "my-app"
    repository  = "my-repository"
  }

  assert {
    condition     = aws_codepipeline.codepipeline.name == "my-app-environment-pipeline"
    error_message = "Invalid name for aws_codepipeline.codepipeline.name, should be: my-app-environment-pipeline"
  }

  # Cannot test aws_codepipeline.codepipeline.role_arn on a plan

  # IAM Role for the pipeline.
  assert {
    condition     = aws_iam_role.environment_pipeline_role.name == "my-app-environment-pipeline-role"
    error_message = "Invalid value for aws_iam_role.environment_pipeline_role.name, should be: 'my-app-environment-pipeline-role'"
  }

  # Tags
  assert {
    condition     = jsonencode(aws_iam_role.environment_pipeline_role.tags) == jsonencode(var.expected_tags)
    error_message = "Invalid value for aws_iam_role.environment_pipeline_role.tags, should be: ${jsonencode(var.expected_tags)}"
  }

  # S3 artifact-store bucket.
  assert {
    condition     = module.artifact_store.bucket_name == "my-app-environment-pipeline-artifact-store"
    error_message = "Invalid name for aws_s3_bucket, should be: my-app-environment-pipeline-artifact-store"
  }
}

# Todo: Confirm with Ant what we are testing here
run "test_create_pipeline_with_different_application" {
  command = plan

  variables {
    application = "my-other-app"
    repository  = "my-repository"
    expected_tags = {
      application         = "my-other-app"
      copilot-application = "my-other-app"
      managed-by          = "DBT Platform - Terraform"
    }
  }

  assert {
    condition     = aws_codepipeline.codepipeline.name == "my-other-app-environment-pipeline"
    error_message = "Invalid value for aws_codepipeline.codepipeline.name, should be: 'my-other-app-environment-pipeline'"
  }

  assert {
    condition     = aws_iam_role.environment_pipeline_role.name == "my-other-app-environment-pipeline-role"
    error_message = "Invalid value for aws_iam_role.environment_pipeline_role.name, should be: 'my-other-app-environment-pipeline-role'"
  }

  # Tags
  assert {
    condition     = jsonencode(aws_iam_role.environment_pipeline_role.tags) == jsonencode(var.expected_tags)
    error_message = "Invalid value for aws_iam_role.environment_pipeline_role.tags, should be: ${jsonencode(var.expected_tags)}"
  }
}
