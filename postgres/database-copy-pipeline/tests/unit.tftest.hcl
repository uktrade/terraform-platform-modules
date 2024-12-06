mock_provider "aws" {}

override_data {
  target = data.aws_iam_policy_document.assume_codepipeline_role
  values = {
    json = "{\"Sid\": \"AssumeCodePipeline\"}"
  }
}

override_data {
  target = data.aws_iam_policy_document.access_artifact_store
  values = {
    json = "{\"Sid\": \"AccessArtifactStore\"}"
  }
}

override_data {
  target = data.aws_iam_policy_document.assume_codebuild_role
  values = {
    json = "{\"Sid\": \"AssumeCodeBuild\"}"
  }
}

override_data {
  target = data.aws_iam_policy_document.database_copy
  values = {
    json = "{\"Sid\": \"DatabaseCopyAccess\"}"
  }
}

override_data {
  target = data.aws_iam_policy_document.ssm_access
  values = {
    json = "{\"Sid\": \"SSMAccess\"}"
  }
}

override_data {
  target = data.aws_iam_policy_document.iam_access
  values = {
    json = "{\"Sid\": \"IAMAccess\"}"
  }
}

override_data {
  target = data.aws_iam_policy_document.assume_database_pipeline_scheduler_role
  values = {
    json = "{\"Sid\": \"AssumePipelineScheduler\"}"
  }
}

override_data {
  target = data.aws_iam_policy_document.pipeline_access_for_database_pipeline_scheduler
  values = {
    json = "{\"Sid\": \"SchedulerPipelineAccess\"}"
  }
}

variables {
  application   = "test-app"
  environment   = "test-env"
  database_name = "test-db"
  task = {
    from : "prod"
    to : "dev"
    pipeline : {
      schedule: "0 1 * * ? *"
    }
  }
  expected_tags = {
    application         = "test-app"
    environment         = "test-env"
    copilot-application = "test-app"
    copilot-environment = "test-env"
    managed-by          = "DBT Platform - Terraform"
  }
}

run "data_copy_pipeline_test" {
  command = plan

  assert {
    condition     = aws_codepipeline.database_copy_pipeline.name == "test-db-prod-to-dev-copy-pipeline"
    error_message = "Should be: test-db-prod-to-dev-copy-pipeline"
  }
  assert {
    condition     = tolist(aws_codepipeline.database_copy_pipeline.artifact_store)[0].location == "test-db-prod-to-dev-copy-pipeline-artifact-store"
    error_message = "Should be: test-db-prod-to-dev-copy-pipeline-artifact-store"
  }
  assert {
    condition     = tolist(aws_codepipeline.database_copy_pipeline.artifact_store)[0].type == "S3"
    error_message = "Should be: S3"
  }
  assert {
    condition     = tolist(aws_codepipeline.database_copy_pipeline.artifact_store)[0].encryption_key[0].type == "KMS"
    error_message = "Should be: KMS"
  }
  assert {
    condition     = jsonencode(aws_codepipeline.database_copy_pipeline.tags) == jsonencode(var.expected_tags)
    error_message = "Should be: ${jsonencode(var.expected_tags)}"
  }

  # Source stage
  assert {
    condition     = aws_codepipeline.database_copy_pipeline.stage[0].name == "Source"
    error_message = "Should be: Source"
  }
  assert {
    condition     = aws_codepipeline.database_copy_pipeline.stage[0].action[0].name == "GitCheckout"
    error_message = "Should be: Git checkout"
  }
  assert {
    condition     = aws_codepipeline.database_copy_pipeline.stage[0].action[0].category == "Source"
    error_message = "Should be: Source"
  }
  assert {
    condition     = aws_codepipeline.database_copy_pipeline.stage[0].action[0].owner == "AWS"
    error_message = "Should be: AWS"
  }
  assert {
    condition     = aws_codepipeline.database_copy_pipeline.stage[0].action[0].provider == "CodeStarSourceConnection"
    error_message = "Should be: CodeStarSourceConnection"
  }
  assert {
    condition     = aws_codepipeline.database_copy_pipeline.stage[0].action[0].version == "1"
    error_message = "Should be: 1"
  }
  assert {
    condition     = one(aws_codepipeline.database_copy_pipeline.stage[0].action[0].output_artifacts) == "project_deployment_source"
    error_message = "Should be: source_output"
  }
  assert {
    condition     = aws_codepipeline.database_copy_pipeline.stage[0].action[0].configuration.FullRepositoryId == "uktrade/test-app-deploy"
    error_message = "Should be: uktrade/test-app-deploy"
  }
  assert {
    condition     = aws_codepipeline.database_copy_pipeline.stage[0].action[0].configuration.BranchName == "main"
    error_message = "Should be: main"
  }
  assert {
    condition     = aws_codepipeline.database_copy_pipeline.stage[0].action[0].configuration.DetectChanges == "false"
    error_message = "Should be: false"
  }

  # Build stage
  assert {
    condition     = aws_codepipeline.database_copy_pipeline.stage[1].name == "Install-Build-Tools"
    error_message = "Should be: Install-Build-Tools"
  }
  assert {
    condition     = aws_codepipeline.database_copy_pipeline.stage[1].action[0].name == "InstallTools"
    error_message = "Should be: InstallTools"
  }
  assert {
    condition     = aws_codepipeline.database_copy_pipeline.stage[1].action[0].category == "Build"
    error_message = "Should be: Build"
  }
  assert {
    condition     = aws_codepipeline.database_copy_pipeline.stage[1].action[0].owner == "AWS"
    error_message = "Should be: AWS"
  }
  assert {
    condition     = aws_codepipeline.database_copy_pipeline.stage[1].action[0].provider == "CodeBuild"
    error_message = "Should be: CodeBuild"
  }
  assert {
    condition     = aws_codepipeline.database_copy_pipeline.stage[1].action[0].version == "1"
    error_message = "Should be: 1"
  }
  assert {
    condition     = one(aws_codepipeline.database_copy_pipeline.stage[1].action[0].input_artifacts) == "project_deployment_source"
    error_message = "Should be: project_deployment_source"
  }
  assert {
    condition     = one(aws_codepipeline.database_copy_pipeline.stage[1].action[0].output_artifacts) == "build_output"
    error_message = "Should be: build_output"
  }
  assert {
    condition     = aws_codepipeline.database_copy_pipeline.stage[1].action[0].configuration.ProjectName == "test-db-prod-to-dev-copy-pipeline-build"
    error_message = "Should be: test-db-prod-to-dev-copy-pipeline-build"
  }
  assert {
    condition     = aws_codepipeline.database_copy_pipeline.stage[1].action[0].configuration.PrimarySource == "project_deployment_source"
    error_message = "Should be: project_deployment_source"
  }
}
