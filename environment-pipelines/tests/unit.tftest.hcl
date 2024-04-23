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
    error_message = "Should be: my-app-environment-pipeline"
  }
  # aws_codepipeline.codepipeline.role_arn cannot be tested on a plan
  assert {
    condition     = tolist(aws_codepipeline.codepipeline.artifact_store)[0].location == "my-app-environment-pipeline-artifact-store"
    error_message = "Should be: my-app-environment-pipeline-artifact-store"
  }
  assert {
    condition     = tolist(aws_codepipeline.codepipeline.artifact_store)[0].type == "S3"
    error_message = "Should be: S3"
  }
  # aws_codepipeline.codepipeline.artifact_store.encryption_key.id cannot be tested on a plan
  assert {
    condition     = tolist(aws_codepipeline.codepipeline.artifact_store)[0].encryption_key[0].type == "KMS"
    error_message = "Should be: KMS"
  }
  assert {
    condition     = aws_codepipeline.codepipeline.stage[0].name == "Source"
    error_message = "Should be: Source"
  }
  assert {
    condition     = aws_codepipeline.codepipeline.stage[0].action[0].name == "Source"
    error_message = "Should be: Source"
  }
  assert {
    condition     = aws_codepipeline.codepipeline.stage[0].action[0].owner == "AWS"
    error_message = "Should be: AWS"
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
    error_message = "Should be: 'my-app-environment-pipeline-role'"
  }

  # Tags
  assert {
    condition     = jsonencode(aws_iam_role.environment_pipeline_role.tags) == jsonencode(var.expected_tags)
    error_message = "Should be: ${jsonencode(var.expected_tags)}"
  }

  # artifact-store S3 bucket.
  assert {
    condition     = module.artifact_store.bucket_name == "my-app-environment-pipeline-artifact-store"
    error_message = "Should be: my-app-environment-pipeline-artifact-store"
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
    error_message = "Should be: 'my-other-app-environment-pipeline'"
  }

  assert {
    condition     = aws_iam_role.environment_pipeline_role.name == "my-other-app-environment-pipeline-role"
    error_message = "Should be: 'my-other-app-environment-pipeline-role'"
  }

  # Tags
  assert {
    condition     = jsonencode(aws_iam_role.environment_pipeline_role.tags) == jsonencode(var.expected_tags)
    error_message = "Should be: ${jsonencode(var.expected_tags)}"
  }
}
