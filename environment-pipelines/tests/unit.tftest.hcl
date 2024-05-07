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
          id   = "000123456789"
        }
        dns = {
          name = "dev"
          id   = "000987654321"
        }
      }
    },
    {
      name = "prod",
      accounts = {
        deploy = {
          name = "prod"
          id   = "000123456789"
        }
        dns = {
          name = "live"
          id   = "000987654321"
        }
      }
      requires_approval = true
    }
  ]
}

run "test_code_pipeline" {
  command = plan

  assert {
    condition     = aws_codepipeline.environment_pipeline.name == "my-app-environment-pipeline-build"
    error_message = "Should be: my-app-environment-pipeline-build"
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
    condition     = aws_codepipeline.environment_pipeline.stage[1].action[0].configuration.ProjectName == "my-app-environment-pipeline-build"
    error_message = "Should be: my-app-environment-pipeline-build"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[1].action[0].configuration.PrimarySource == "project_deployment_source"
    error_message = "Should be: project_deployment_source"
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
    condition     = aws_codebuild_project.environment_pipeline_build.name == "my-app-environment-pipeline-build"
    error_message = "Should be: my-app-environment-pipeline-build"
  }
  assert {
    condition     = aws_codebuild_project.environment_pipeline_build.description == "Provisions the my-app application's extensions."
    error_message = "Should be: 'Provisions the my-app application's extensions.'"
  }
  assert {
    condition     = aws_codebuild_project.environment_pipeline_build.build_timeout == 5
    error_message = "Should be: 5"
  }
  assert {
    condition     = one(aws_codebuild_project.environment_pipeline_build.artifacts).type == "CODEPIPELINE"
    error_message = "Should be: 'CODEPIPELINE'"
  }
  assert {
    condition     = one(aws_codebuild_project.environment_pipeline_build.cache).type == "S3"
    error_message = "Should be: 'S3'"
  }
  assert {
    condition     = one(aws_codebuild_project.environment_pipeline_build.cache).location == "my-app-environment-pipeline-artifact-store"
    error_message = "Should be: 'my-app-environment-pipeline-artifact-store'"
  }
  assert {
    condition     = one(aws_codebuild_project.environment_pipeline_build.environment).compute_type == "BUILD_GENERAL1_SMALL"
    error_message = "Should be: 'BUILD_GENERAL1_SMALL'"
  }
  assert {

    condition     = one(aws_codebuild_project.environment_pipeline_build.environment).image == "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    error_message = "Should be: 'aws/codebuild/amazonlinux2-x86_64-standard:5.0'"
  }
  assert {
    condition     = one(aws_codebuild_project.environment_pipeline_build.environment).type == "LINUX_CONTAINER"
    error_message = "Should be: 'LINUX_CONTAINER'"
  }
  assert {
    condition     = one(aws_codebuild_project.environment_pipeline_build.environment).image_pull_credentials_type == "CODEBUILD"
    error_message = "Should be: 'CODEBUILD'"
  }
  assert {
    condition     = aws_codebuild_project.environment_pipeline_build.logs_config[0].cloudwatch_logs[0].group_name == "codebuild/my-app-environment-terraform/log-group"
    error_message = "Should be: 'codebuild/my-app-environment-terraform/log-group'"
  }
  assert {
    condition     = aws_codebuild_project.environment_pipeline_build.logs_config[0].cloudwatch_logs[0].stream_name == "codebuild/my-app-environment-terraform/log-stream"
    error_message = "Should be: 'codebuild/my-app-environment-terraform/log-group'"
  }
  assert {
    condition     = one(aws_codebuild_project.environment_pipeline_build.source).type == "CODEPIPELINE"
    error_message = "Should be: 'CODEPIPELINE'"
  }
  assert {
    condition     = length(regexall(".*echo \"Install Phase\".*", aws_codebuild_project.environment_pipeline_build.source[0].buildspec)) > 0
    error_message = "Should contain: 'echo \"Install Phase\"'"
  }
  assert {
    condition     = jsonencode(aws_codebuild_project.environment_pipeline_build.tags) == jsonencode(var.expected_tags)
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
  # aws_iam_role_policy.log_access_for_environment_codebuild.policy cannot be tested on a plan
  assert {
    condition     = aws_iam_role_policy.state_bucket_access_for_environment_codebuild.name == "my-app-state-bucket-access-for-environment-codebuild"
    error_message = "Should be: 'my-app-state-bucket-access-for-environment-codebuild'"
  }
  assert {
    condition     = aws_iam_role_policy.state_bucket_access_for_environment_codebuild.role == "my-app-environment-pipeline-codebuild"
    error_message = "Should be: 'my-app-environment-pipeline-codebuild'"
  }
  # aws_iam_role_policy.state_bucket_access_for_environment_codebuild.policy cannot be tested on a plan
  assert {
    condition     = aws_iam_role_policy.state_kms_key_access_for_environment_codebuild.name == "my-app-state-kms-key-access-for-environment-codebuild"
    error_message = "Should be: 'my-app-state-kms-key-access-for-environment-codebuild'"
  }
  assert {
    condition     = aws_iam_role_policy.state_kms_key_access_for_environment_codebuild.role == "my-app-environment-pipeline-codebuild"
    error_message = "Should be: 'my-app-environment-pipeline-codebuild'"
  }
  # aws_iam_role_policy.state_kms_key_access_for_environment_codebuild.policy cannot be tested on a plan
  assert {
    condition     = aws_iam_role_policy.state_dynamo_db_access_for_environment_codebuild.name == "my-app-state-dynamo-db-access-for-environment-codebuild"
    error_message = "Should be: 'my-app-state-dynamo-db-access-for-environment-codebuild'"
  }
  assert {
    condition     = aws_iam_role_policy.state_dynamo_db_access_for_environment_codebuild.role == "my-app-environment-pipeline-codebuild"
    error_message = "Should be: 'my-app-environment-pipeline-codebuild'"
  }
  # aws_iam_role_policy.state_dynamo_db_access_for_environment_codebuild.policy cannot be tested on a plan
  assert {
    condition     = aws_iam_role_policy.ec2_read_access_for_environment_codebuild.name == "my-app-ec2-read-access-for-environment-codebuild"
    error_message = "Should be: 'my-app-ec2-read-access-for-environment-codebuild'"
  }
  assert {
    condition     = aws_iam_role_policy.ec2_read_access_for_environment_codebuild.role == "my-app-environment-pipeline-codebuild"
    error_message = "Should be: 'my-app-environment-pipeline-codebuild'"
  }
  # aws_iam_role_policy.ec2_read_access_for_environment_codebuild.policy cannot be tested on a plan
  assert {
    condition     = aws_iam_role_policy.ssm_read_access_for_environment_codebuild.name == "my-app-ssm-read-access-for-environment-codebuild"
    error_message = "Should be: 'my-app-ssm-read-access-for-environment-codebuild'"
  }
  assert {
    condition     = aws_iam_role_policy.ssm_read_access_for_environment_codebuild.role == "my-app-environment-pipeline-codebuild"
    error_message = "Should be: 'my-app-environment-pipeline-codebuild'"
  }
  # aws_iam_role_policy.ssm_read_access_for_environment_codebuild.policy cannot be tested on a plan
  assert {
    condition     = aws_iam_role_policy.dns_account_assume_role_for_environment_codebuild.name == "my-app-dns-account-assume-role-for-environment-codebuild"
    error_message = "Should be: 'my-app-dns-account-assume-role-for-environment-codebuild'"
  }
  assert {
    condition     = aws_iam_role_policy.dns_account_assume_role_for_environment_codebuild.role == "my-app-environment-pipeline-codebuild"
    error_message = "Should be: 'my-app-environment-pipeline-codebuild'"
  }
  # aws_iam_role_policy.dns_account_assume_role_for_environment_codebuild.policy cannot be tested on a plan
}

run "test_artifact_store" {
  command = plan

  # artifact-store S3 bucket.
  assert {
    condition     = module.artifact_store.bucket_name == "my-app-environment-pipeline-artifact-store"
    error_message = "Should be: my-app-environment-pipeline-artifact-store"
  }
}

run "test_stages" {
  command = plan

  assert {
    condition     = length(aws_codepipeline.environment_pipeline.stage) == 7
    error_message = "Should be: 7"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[0].name == "Source"
    error_message = "Should be: Source"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[1].name == "Build"
    error_message = "Should be: Build"
  }

  # Stage: dev plan
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[2].name == "Plan-dev"
    error_message = "Should be: Plan-dev"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[2].action[0].name == "Plan"
    error_message = "Action name incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[2].action[0].category == "Build"
    error_message = "Action category incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[2].action[0].owner == "AWS"
    error_message = "Action owner incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[2].action[0].provider == "CodeBuild"
    error_message = "Action provider incorrect"
  }
  assert {
    condition     = length(aws_codepipeline.environment_pipeline.stage[2].action[0].input_artifacts) == 1
    error_message = "Input artifacts incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[2].action[0].input_artifacts[0] == "build_output"
    error_message = "Input artifacts incorrect"
  }
  assert {
    condition     = length(aws_codepipeline.environment_pipeline.stage[2].action[0].output_artifacts) == 1
    error_message = "Output artifacts incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[2].action[0].output_artifacts[0] == "terraform_plan"
    error_message = "Output artifacts incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[2].action[0].version == "1"
    error_message = "Action Version incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[2].action[0].configuration.ProjectName == "my-app-environment-pipeline-plan"
    error_message = "Configuration ProjectName incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[2].action[0].configuration.PrimarySource == "build_output"
    error_message = "Configuration PrimarySource incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[2].action[0].configuration.EnvironmentVariables == "[{\"name\":\"ENVIRONMENT\",\"value\":\"dev\"}]"
    error_message = "Configuration Env Vars incorrect"
  }

  # Stage: dev apply
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[3].name == "Apply-dev"
    error_message = "Should be: Apply-dev"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[3].action[0].name == "Apply"
    error_message = "Action name incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[3].action[0].category == "Build"
    error_message = "Action category incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[3].action[0].owner == "AWS"
    error_message = "Action owner incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[3].action[0].provider == "CodeBuild"
    error_message = "Action provider incorrect"
  }
  assert {
    condition     = length(aws_codepipeline.environment_pipeline.stage[3].action[0].input_artifacts) == 2
    error_message = "Input artifacts incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[3].action[0].input_artifacts[0] == "build_output"
    error_message = "Input artifacts incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[3].action[0].input_artifacts[1] == "terraform_plan"
    error_message = "Input artifacts incorrect"
  }
  assert {
    condition     = length(aws_codepipeline.environment_pipeline.stage[3].action[0].output_artifacts) == 0
    error_message = "Output artifacts incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[3].action[0].version == "1"
    error_message = "Action Version incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[3].action[0].configuration.ProjectName == "my-app-environment-pipeline-apply"
    error_message = "Configuration ProjectName incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[3].action[0].configuration.PrimarySource == "build_output"
    error_message = "Configuration PrimarySource incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[2].action[0].configuration.EnvironmentVariables == "[{\"name\":\"ENVIRONMENT\",\"value\":\"dev\"}]"
    error_message = "Configuration Env Vars incorrect"
  }

  # Stage: prod Plan
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[4].name == "Plan-prod"
    error_message = "Should be: Plan-prod"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[4].action[0].name == "Plan"
    error_message = "Action name incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[4].action[0].category == "Build"
    error_message = "Action category incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[4].action[0].owner == "AWS"
    error_message = "Action owner incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[4].action[0].provider == "CodeBuild"
    error_message = "Action provider incorrect"
  }
  assert {
    condition     = length(aws_codepipeline.environment_pipeline.stage[4].action[0].input_artifacts) == 1
    error_message = "Input artifacts incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[4].action[0].input_artifacts[0] == "build_output"
    error_message = "Input artifacts incorrect"
  }
  assert {
    condition     = length(aws_codepipeline.environment_pipeline.stage[4].action[0].output_artifacts) == 1
    error_message = "Output artifacts incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[4].action[0].output_artifacts[0] == "terraform_plan"
    error_message = "Output artifacts incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[4].action[0].version == "1"
    error_message = "Action Version incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[4].action[0].configuration.ProjectName == "my-app-environment-pipeline-plan"
    error_message = "Configuration ProjectName incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[4].action[0].configuration.PrimarySource == "build_output"
    error_message = "Configuration PrimarySource incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[4].action[0].configuration.EnvironmentVariables == "[{\"name\":\"ENVIRONMENT\",\"value\":\"prod\"}]"
    error_message = "Configuration Env Vars incorrect"
  }

  # Stage: prod approval
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[5].name == "Approve-prod"
    error_message = "Should be: Approve-prod"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[5].action[0].name == "Approval"
    error_message = "Action name incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[5].action[0].category == "Approval"
    error_message = "Action category incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[5].action[0].owner == "AWS"
    error_message = "Action owner incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[5].action[0].provider == "Manual"
    error_message = "Action provider incorrect"
  }
  assert {
    condition     = length(aws_codepipeline.environment_pipeline.stage[5].action[0].input_artifacts) == 0
    error_message = "Input artifacts incorrect"
  }
  assert {
    condition     = length(aws_codepipeline.environment_pipeline.stage[5].action[0].output_artifacts) == 0
    error_message = "Output artifacts incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[5].action[0].version == "1"
    error_message = "Action Version incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[5].action[0].configuration.CustomData == "Review Terraform Plan"
    error_message = "Configuration CustomData incorrect"
  }

  # Stage: prod apply
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[6].name == "Apply-prod"
    error_message = "Should be: Apply-prod"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[6].action[0].name == "Apply"
    error_message = "Action name incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[6].action[0].category == "Build"
    error_message = "Action category incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[6].action[0].owner == "AWS"
    error_message = "Action owner incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[6].action[0].provider == "CodeBuild"
    error_message = "Action provider incorrect"
  }
  assert {
    condition     = length(aws_codepipeline.environment_pipeline.stage[6].action[0].input_artifacts) == 2
    error_message = "Input artifacts incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[6].action[0].input_artifacts[0] == "build_output"
    error_message = "Input artifacts incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[6].action[0].input_artifacts[1] == "terraform_plan"
    error_message = "Input artifacts incorrect"
  }
  assert {
    condition     = length(aws_codepipeline.environment_pipeline.stage[6].action[0].output_artifacts) == 0
    error_message = "Output artifacts incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[6].action[0].version == "1"
    error_message = "Action Version incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[6].action[0].configuration.ProjectName == "my-app-environment-pipeline-apply"
    error_message = "Configuration ProjectName incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[6].action[0].configuration.PrimarySource == "build_output"
    error_message = "Configuration PrimarySource incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[6].action[0].configuration.EnvironmentVariables == "[{\"name\":\"ENVIRONMENT\",\"value\":\"prod\"}]"
    error_message = "Configuration Env Vars incorrect"
  }
}

