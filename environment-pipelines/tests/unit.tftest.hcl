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

override_data {
  target = data.aws_iam_policy_document.ec2_read_access
  values = {
    json = "{\"Sid\": \"EC2ReadAccess\"}"
  }
}

override_data {
  target = data.aws_iam_policy_document.state_bucket_access
  values = {
    json = "{\"Sid\": \"StateBucketAccess\"}"
  }
}

override_data {
  target = data.aws_iam_policy_document.state_kms_key_access
  values = {
    json = "{\"Sid\": \"StateKMSKeyAccess\"}"
  }
}

override_data {
  target = data.aws_iam_policy_document.state_dynamo_db_access
  values = {
    json = "{\"Sid\": \"StateDynamoDBAccess\"}"
  }
}

override_data {
  target = data.aws_iam_policy_document.ssm_read_access
  values = {
    json = "{\"Sid\": \"SSMReadAccess\"}"
  }
}

override_data {
  target = data.aws_iam_policy_document.dns_account_assume_role
  values = {
    json = "{\"Sid\": \"DNSAccountAssumeRole\"}"
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

  environments = [
    {
      name = "dev",
      accounts = {
        deploy = {
          name = "sandbox"
          id = "000123456789"
        }
        dns = {
          name = "dev"
          id = "000987654321"
        }
      }
    },
    {
      name = "prod",
      accounts = {
        deploy = {
          name = "prod"
          id = "000123456789"
        }
        dns = {
          name = "live"
          id = "000987654321"
        }
      }
      requires_approval = true
    }
  ]
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
    condition     = one(aws_codepipeline.environment_pipeline.stage[0].action[0].output_artifacts) == "project_deployment_source"
    error_message = "Should be: source_output"
  }
  # aws_codepipeline.environment_pipeline.stage[0].action[0].configuration.ConnectionArn cannot be tested on a plan
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[0].action[0].configuration.FullRepositoryId == "my-repository"
    error_message = "Should be: my-repository"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[0].action[0].configuration.BranchName == "main"
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
    condition     = one(aws_codepipeline.environment_pipeline.stage[1].action[0].input_artifacts) == "project_deployment_source"
    error_message = "Should be: project_deployment_source"
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

run "test_codebuild" {
  command = plan

  assert {
    condition     = aws_codebuild_project.environment_pipeline.name == "my-app-environment-pipeline"
    error_message = "Should be: my-app-environment-pipeline"
  }
  assert {
    condition     = aws_codebuild_project.environment_pipeline.description == "Provisions the my-app application's extensions."
    error_message = "Should be: 'Provisions the my-app application's extensions.'"
  }
  assert {
    condition     = aws_codebuild_project.environment_pipeline.build_timeout == 5
    error_message = "Should be: 5"
  }
  assert {
    condition     = one(aws_codebuild_project.environment_pipeline.artifacts).type == "CODEPIPELINE"
    error_message = "Should be: 'CODEPIPELINE'"
  }
  assert {
    condition     = one(aws_codebuild_project.environment_pipeline.cache).type == "S3"
    error_message = "Should be: 'S3'"
  }
  assert {
    condition     = one(aws_codebuild_project.environment_pipeline.cache).location == "my-app-environment-pipeline-artifact-store"
    error_message = "Should be: 'my-app-environment-pipeline-artifact-store'"
  }
  assert {
    condition     = one(aws_codebuild_project.environment_pipeline.environment).compute_type == "BUILD_GENERAL1_SMALL"
    error_message = "Should be: 'BUILD_GENERAL1_SMALL'"
  }
  assert {

    condition     = one(aws_codebuild_project.environment_pipeline.environment).image == "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    error_message = "Should be: 'aws/codebuild/amazonlinux2-x86_64-standard:5.0'"
  }
  assert {
    condition     = one(aws_codebuild_project.environment_pipeline.environment).type == "LINUX_CONTAINER"
    error_message = "Should be: 'LINUX_CONTAINER'"
  }
  assert {
    condition     = one(aws_codebuild_project.environment_pipeline.environment).image_pull_credentials_type == "CODEBUILD"
    error_message = "Should be: 'CODEBUILD'"
  }
  assert {
    condition     = aws_codebuild_project.environment_pipeline.logs_config[0].cloudwatch_logs[0].group_name == "codebuild/my-app-environment-terraform/log-group"
    error_message = "Should be: 'codebuild/my-app-environment-terraform/log-group'"
  }
  assert {
    condition     = aws_codebuild_project.environment_pipeline.logs_config[0].cloudwatch_logs[0].stream_name == "codebuild/my-app-environment-terraform/log-stream"
    error_message = "Should be: 'codebuild/my-app-environment-terraform/log-group'"
  }
  assert {
    condition     = one(aws_codebuild_project.environment_pipeline.source).type == "CODEPIPELINE"
    error_message = "Should be: 'CODEPIPELINE'"
  }
  assert {
    condition     = length(regexall(".*echo \"Install Phase\".*", aws_codebuild_project.environment_pipeline.source[0].buildspec)) > 0
    error_message = "Should contain: 'echo \"Install Phase\"'"
  }
  assert {
    condition     = jsonencode(aws_codebuild_project.environment_pipeline.tags) == jsonencode(var.expected_tags)
    error_message = "Should be: ${jsonencode(var.expected_tags)}"
  }

  # Cloudwatch config:
  assert {
    condition     = aws_cloudwatch_log_group.environment_pipeline_codebuild.name == "codebuild/my-app-environment-terraform/log-group"
    error_message = "Should be: 'codebuild/my-app-environment-terraform/log-group'"
  }
  assert {
    condition     = aws_cloudwatch_log_group.environment_pipeline_codebuild.retention_in_days == 90
    error_message = "Should be: 90"
  }
  assert {
    condition     = aws_cloudwatch_log_stream.environment_pipeline_codebuild.name == "codebuild/my-app-environment-terraform/log-stream"
    error_message = "Should be: 'codebuild/my-app-environment-terraform/log-stream'"
  }
  assert {
    condition     = aws_cloudwatch_log_stream.environment_pipeline_codebuild.log_group_name == "codebuild/my-app-environment-terraform/log-group"
    error_message = "Should be: 'codebuild/my-app-environment-terraform/log-group'"
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
  assert {
    condition     = jsonencode(aws_iam_role.environment_pipeline_codebuild.tags) == jsonencode(var.expected_tags)
    error_message = "Should be: ${jsonencode(var.expected_tags)}"
  }

  # Policy links
  assert {
    condition     = aws_iam_role_policy.artifact_store_access_for_environment_codepipeline.name == "my-app-artifact-store-access-for-environment-codepipeline"
    error_message = "Should be: 'my-app-artifact-store-access-for-environment-codepipeline'"
  }
  assert {
    condition     = aws_iam_role_policy.artifact_store_access_for_environment_codepipeline.role == "my-app-environment-pipeline-codepipeline"
    error_message = "Should be: 'my-app-environment-pipeline-codepipeline'"
  }
  # aws_iam_role_policy.artifact_store_access_for_environment_codepipeline.policy cannot be tested on a plan
  assert {
    condition     = aws_iam_role_policy.artifact_store_access_for_environment_codebuild.name == "my-app-artifact-store-access-for-environment-codebuild"
    error_message = "Should be: 'my-app-artifact-store-access-for-environment-codebuild'"
  }
  assert {
    condition     = aws_iam_role_policy.artifact_store_access_for_environment_codebuild.role == "my-app-environment-pipeline-codebuild"
    error_message = "Should be: 'my-app-environment-pipeline-codebuild'"
  }
  # aws_iam_role_policy.artifact_store_access_for_environment_codebuild.policy cannot be tested on a plan
  assert {
    condition     = aws_iam_role_policy.log_access_for_environment_codebuild.name == "my-app-log-access-for-environment-codebuild"
    error_message = "Should be: 'my-app-log-access-for-environment-codebuild'"
  }
  assert {
    condition     = aws_iam_role_policy.log_access_for_environment_codebuild.role == "my-app-environment-pipeline-codebuild"
    error_message = "Should be: 'my-app-environment-pipeline-codebuild'"
  }
  # aws_iam_role_policy.artifact_store_access_for_environment_codepipeline.policy cannot be tested on a plan
}

run "test_artifact_store" {
  command = plan

  # artifact-store S3 bucket.
  assert {
    condition     = module.artifact_store.bucket_name == "my-app-environment-pipeline-artifact-store"
    error_message = "Should be: my-app-environment-pipeline-artifact-store"
  }
}

