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

  # CodePipeline
  variables {
    application = "my-app"
    repository  = "my-repository"
  }
  assert {
    condition     = aws_codepipeline.codepipeline.name == "my-app-environment-pipeline"
    error_message = "Invalid name for aws_codepipeline.codepipeline.name, should be: my-app-environment-pipeline"
  }
  # Cannot test aws_codepipeline.codepipeline.role_arn on a plan
#  assert {
#    condition     = [for key, value in aws_codepipeline.codepipeline.artifact_store : value if key == "location"] == "my-app-environment-pipeline-artifact-store"
##    condition = aws_codepipeline.codepipeline.artifact_store.location == "my-app-environment-pipeline-artifact-store"
##    condition = aws_codepipeline.codepipeline.artifact_store[0].location == "my-app-environment-pipeline-artifact-store"
#    error_message = "Invalid name for aws_codepipeline.codepipeline.artifact_store.location, should be: my-app-environment-pipeline-artifact-store"
#  }
  assert {
    condition     = aws_codepipeline.codepipeline.stage[0].name == "Source"
    error_message = "Invalid name for aws_codepipeline.codepipeline.name, should be: Source"
  }
  assert {
    condition     = aws_codepipeline.codepipeline.stage[0].action[0].name == "Source"
    error_message = "Invalid name for aws_codepipeline.codepipeline.action.name, should be: Source"
  }
  assert {
    condition     = aws_codepipeline.codepipeline.stage[0].action[0].owner == "AWS"
    error_message = "Invalid name for aws_codepipeline.codepipeline.action.owner, should be: AWS"
  }
  assert {
    condition     = aws_codepipeline.codepipeline.stage[0].action[0].provider == "CodeStarSourceConnection"
    error_message = "Should be: CodeStarSourceConnection"
  }
  assert {
    condition     = aws_codepipeline.codepipeline.stage[0].action[0].version == "1"
    error_message = "Should be: 1"
  }
  assert {
    condition     = one(aws_codepipeline.codepipeline.stage[0].action[0].output_artifacts) == "source_output"
    error_message = "Should be: [\"source_output\"]"
  }

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

  # artifact-store S3 bucket.
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
