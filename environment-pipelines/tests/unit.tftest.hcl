mock_provider "aws" {}

override_data {
  target = data.aws_iam_policy_document.assume_codepipeline_role
  values = {
    json = "{\"Sid\": \"AssumePipelineRole\"}"
  }
}

override_data {
  target = data.aws_iam_policy_document.assume_codebuild_role
  values = {
    json = "{\"Sid\": \"AssumeCodebuildRole\"}"
  }
}

variables {
  application = "my-app"
  repository  = "my-repository"
  expected_tags = {
    application         = "my-app"
    copilot-application = "my-app"
    managed-by          = "DBT Platform - Terraform"
  }
}

run "test_code_pipeline" {
  command = plan

  assert {
    condition     = aws_codepipeline.environment_pipeline.name == "my-app-environment-pipeline"
    error_message = "Should be: my-app-environment-pipeline"
  }
  # aws_codepipeline.environment_pipeline.role_arn cannot be tested on a plan
  assert {
    condition     = tolist(aws_codepipeline.environment_pipeline.artifact_store)[0].location == "my-app-environment-pipeline-artifact-store"
    error_message = "Should be: my-app-environment-pipeline-artifact-store"
  }
  assert {
    condition     = tolist(aws_codepipeline.environment_pipeline.artifact_store)[0].type == "S3"
    error_message = "Should be: S3"
  }
  # aws_codepipeline.environment_pipeline.artifact_store.encryption_key.id cannot be tested on a plan
  assert {
    condition     = tolist(aws_codepipeline.environment_pipeline.artifact_store)[0].encryption_key[0].type == "KMS"
    error_message = "Should be: KMS"
  }

  # Source stage
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[0].name == "Source"
    error_message = "Should be: Source"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[0].action[0].name == "GitCheckout"
    error_message = "Should be: Git checkout"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[0].action[0].category == "Source"
    error_message = "Should be: Source"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[0].action[0].owner == "AWS"
    error_message = "Should be: AWS"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[0].action[0].provider == "CodeStarSourceConnection"
    error_message = "Should be: CodeStarSourceConnection"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[0].action[0].version == "1"
    error_message = "Should be: 1"
  }
  assert {
    condition     = one(aws_codepipeline.environment_pipeline.stage[0].action[0].output_artifacts) == "source_output"
    error_message = "Should be: source_output"
  }
  # aws_codepipeline.environment_pipeline.stage[0].action[0].configuration.ConnectionArn cannot be tested on a plan
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[0].action[0].configuration.FullRepositoryId == "my-repository"
    error_message = "Should be: my-repository"
  }
  assert {
    # TODO: Revert this back to "main" before merging.
    condition     = aws_codepipeline.environment_pipeline.stage[0].action[0].configuration.BranchName == "DBTP-911-Barebones-Pipeline"
    error_message = "Should be: main"
  }

  # Build stage
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[1].name == "Build"
    error_message = "Should be: Build"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[1].action[0].name == "InstallTools"
    error_message = "Should be: InstallTools"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[1].action[0].category == "Build"
    error_message = "Should be: Build"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[1].action[0].owner == "AWS"
    error_message = "Should be: AWS"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[1].action[0].provider == "CodeBuild"
    error_message = "Should be: CodeBuild"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[1].action[0].version == "1"
    error_message = "Should be: 1"
  }
  assert {
    condition     = one(aws_codepipeline.environment_pipeline.stage[1].action[0].input_artifacts) == "source_output"
    error_message = "Should be: source_output"
  }
  assert {
    condition     = one(aws_codepipeline.environment_pipeline.stage[1].action[0].output_artifacts) == "build_output"
    error_message = "Should be: build_output"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[1].action[0].configuration.ProjectName == "my-app-environment-pipeline"
    error_message = "Should be: my-app-environment-pipeline"
  }

  # Tags
  assert {
    condition     = jsonencode(aws_codepipeline.environment_pipeline.tags) == jsonencode(var.expected_tags)
    error_message = "Should be: ${jsonencode(var.expected_tags)}"
  }
}

run "test_iam" {
  command = plan

  # IAM Role for the pipeline.
  assert {
    condition     = aws_iam_role.environment_pipeline_codepipeline.name == "my-app-environment-pipeline-codepipeline"
    error_message = "Should be: 'my-app-environment-pipeline-codepipeline'"
  }

  assert {
    condition     = aws_iam_role.environment_pipeline_codepipeline.assume_role_policy == "{\"Sid\": \"AssumePipelineRole\"}"
    error_message = "Should be: {\"Sid\": \"AssumePipelineRole\"}"
  }

  # Tags
  assert {
    condition     = jsonencode(aws_iam_role.environment_pipeline_codepipeline.tags) == jsonencode(var.expected_tags)
    error_message = "Should be: ${jsonencode(var.expected_tags)}"
  }

  # IAM Role for the codebuild
  assert {
    condition     = aws_iam_role.environment_pipeline_codebuild.name == "my-app-environment-pipeline-codebuild"
    error_message = "Should be: 'my-app-environment-pipeline-codebuild'"
  }

  assert {
    condition     = aws_iam_role.environment_pipeline_codebuild.assume_role_policy == "{\"Sid\": \"AssumeCodebuildRole\"}"
    error_message = "Should be: {\"Sid\": \"AssumeCodebuildRole\"}"
  }

  # Tags
  assert {
    condition     = jsonencode(aws_iam_role.environment_pipeline_codebuild.tags) == jsonencode(var.expected_tags)
    error_message = "Should be: ${jsonencode(var.expected_tags)}"
  }
}

run "test_artifact_store" {
  command = plan

  # artifact-store S3 bucket.
  assert {
    condition     = module.artifact_store.bucket_name == "my-app-environment-pipeline-artifact-store"
    error_message = "Should be: my-app-environment-pipeline-artifact-store"
  }
}
