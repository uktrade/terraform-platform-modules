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

override_data {
  target = data.aws_iam_policy_document.load_balancer
  values = {
    json = "{\"Sid\": \"LoadBalancer\"}"
  }
}

override_data {
  target = data.aws_iam_policy_document.certificate
  values = {
    json = "{\"Sid\": \"Certificate\"}"
  }
}

override_data {
  target = data.aws_iam_policy_document.security_group
  values = {
    json = "{\"Sid\": \"SecurityGroup\"}"
  }
}

override_data {
  target = data.aws_iam_policy_document.ssm_parameter
  values = {
    json = "{\"Sid\": \"SSMParameter\"}"
  }
}

override_data {
  target = data.aws_iam_policy_document.cloudwatch
  values = {
    json = "{\"Sid\": \"Cloudwatch\"}"
  }
}

override_data {
  target = data.aws_iam_policy_document.logs
  values = {
    json = "{\"Sid\": \"Logs\"}"
  }
}

override_data {
  target = data.aws_iam_policy_document.kms_key
  values = {
    json = "{\"Sid\": \"KMSKey\"}"
  }
}

override_data {
  target = data.aws_iam_policy_document.redis
  values = {
    json = "{\"Sid\": \"Redis\"}"
  }
}

override_data {
  target = data.aws_iam_policy_document.postgres
  values = {
    json = "{\"Sid\": \"Postgres\"}"
  }
}

override_data {
  target = data.aws_iam_policy_document.s3
  values = {
    json = "{\"Sid\": \"S3\"}"
  }
}

override_data {
  target = data.aws_iam_policy_document.opensearch
  values = {
    json = "{\"Sid\": \"OpenSearch\"}"
  }
}

override_data {
  target = data.aws_iam_policy_document.cloudformation
  values = {
    json = "{\"Sid\": \"CloudFormation\"}"
  }
}

override_data {
  target = data.aws_iam_policy_document.copilot_assume_role
  values = {
    json = "{\"Sid\": \"Copilot\"}"
  }
}

override_data {
  target = data.aws_iam_policy_document.iam
  values = {
    json = "{\"Sid\": \"IAM\"}"
  }
}

override_data {
  target = data.aws_iam_policy_document.codepipeline
  values = {
    json = "{\"Sid\": \"codepipeline\"}"
  }
}

variables {
  application   = "my-app"
  repository    = "my-repository"
  pipeline_name = "my-pipeline"
  expected_tags = {
    application         = "my-app"
    copilot-application = "my-app"
    managed-by          = "DBT Platform - Terraform"
  }

  environment_config = {
    "*" = {
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
      requires_approval : false
      vpc : "platform-sandbox-dev"
    },
    "dev" = null,
    "prod" = {
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
      vpc : "platform-sandbox-prod"
    }
  }

  environments = {
    "dev" : null
    "prod" : null
  }
}

run "test_code_pipeline" {
  command = plan

  assert {
    condition     = aws_codepipeline.environment_pipeline.name == "my-app-my-pipeline-environment-pipeline"
    error_message = "Should be: my-app-my-pipeline-environment-pipeline"
  }
  # aws_codepipeline.environment_pipeline.role_arn cannot be tested on a plan
  assert {
    condition     = tolist(aws_codepipeline.environment_pipeline.artifact_store)[0].location == "my-app-my-pipeline-environment-pipeline-artifact-store"
    error_message = "Should be: my-app-my-pipeline-environment-pipeline-artifact-store"
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
    condition     = aws_codepipeline.environment_pipeline.stage[1].action[0].configuration.ProjectName == "my-app-my-pipeline-environment-pipeline-build"
    error_message = "Should be: my-app-my-pipeline-environment-pipeline-build"
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
    condition     = aws_codebuild_project.environment_pipeline_build.name == "my-app-my-pipeline-environment-pipeline-build"
    error_message = "Should be: my-app-my-pipeline-environment-pipeline-build"
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
    condition     = one(aws_codebuild_project.environment_pipeline_build.cache).location == "my-app-my-pipeline-environment-pipeline-artifact-store"
    error_message = "Should be: 'my-app-my-pipeline-environment-pipeline-artifact-store'"
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
    condition     = aws_codebuild_project.environment_pipeline_build.logs_config[0].cloudwatch_logs[0].group_name == "codebuild/my-app-my-pipeline-environment-terraform/log-group"
    error_message = "Should be: 'codebuild/my-app-my-pipeline-environment-terraform/log-group'"
  }
  assert {
    condition     = aws_codebuild_project.environment_pipeline_build.logs_config[0].cloudwatch_logs[0].stream_name == "codebuild/my-app-my-pipeline-environment-terraform/log-stream"
    error_message = "Should be: 'codebuild/my-app-my-pipeline-environment-terraform/log-group'"
  }
  assert {
    condition     = one(aws_codebuild_project.environment_pipeline_build.source).type == "CODEPIPELINE"
    error_message = "Should be: 'CODEPIPELINE'"
  }
  assert {
    condition     = length(regexall(".*echo \"Installing build tools\".*", aws_codebuild_project.environment_pipeline_build.source[0].buildspec)) > 0
    error_message = "Should contain: 'echo \"Installing build tools\"'"
  }
  assert {
    condition     = jsonencode(aws_codebuild_project.environment_pipeline_build.tags) == jsonencode(var.expected_tags)
    error_message = "Should be: ${jsonencode(var.expected_tags)}"
  }

  # Cloudwatch config:
  assert {
    condition     = aws_cloudwatch_log_group.environment_pipeline_codebuild.name == "codebuild/my-app-my-pipeline-environment-terraform/log-group"
    error_message = "Should be: 'codebuild/my-app-my-pipeline-environment-terraform/log-group'"
  }
  assert {
    condition     = aws_cloudwatch_log_group.environment_pipeline_codebuild.retention_in_days == 90
    error_message = "Should be: 90"
  }
  assert {
    condition     = aws_cloudwatch_log_stream.environment_pipeline_codebuild.name == "codebuild/my-app-my-pipeline-environment-terraform/log-stream"
    error_message = "Should be: 'codebuild/my-app-my-pipeline-environment-terraform/log-stream'"
  }
  assert {
    condition     = aws_cloudwatch_log_stream.environment_pipeline_codebuild.log_group_name == "codebuild/my-app-my-pipeline-environment-terraform/log-group"
    error_message = "Should be: 'codebuild/my-app-my-pipeline-environment-terraform/log-group'"
  }
}

run "test_iam" {
  command = plan

  # IAM Role for the pipeline.
  assert {
    condition     = aws_iam_role.environment_pipeline_codepipeline.name == "my-app-my-pipeline-environment-pipeline-codepipeline"
    error_message = "Should be: 'my-app-my-pipeline-environment-pipeline-codepipeline'"
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
    condition     = aws_iam_role.environment_pipeline_codebuild.name == "my-app-my-pipeline-environment-pipeline-codebuild"
    error_message = "Should be: 'my-app-my-pipeline-environment-pipeline-codebuild'"
  }
  assert {
    condition     = aws_iam_role.environment_pipeline_codebuild.assume_role_policy == "{\"Sid\": \"AssumeCodebuildRole\"}"
    error_message = "Should be: {\"Sid\": \"AssumeCodebuildRole\"}"
  }
  # Can't test managed_policy_arns of the environment_pipeline_codebuild role at plan time.
  assert {
    condition     = jsonencode(aws_iam_role.environment_pipeline_codebuild.tags) == jsonencode(var.expected_tags)
    error_message = "Should be: ${jsonencode(var.expected_tags)}"
  }

  # Policy links
  assert {
    condition     = aws_iam_role_policy.artifact_store_access_for_environment_codepipeline.name == "my-app-my-pipeline-artifact-store-access-for-environment-codepipeline"
    error_message = "Should be: 'my-app-artifact-store-access-for-environment-codepipeline'"
  }
  assert {
    condition     = aws_iam_role_policy.artifact_store_access_for_environment_codepipeline.role == "my-app-my-pipeline-environment-pipeline-codepipeline"
    error_message = "Should be: 'my-app-my-pipeline-environment-pipeline-codepipeline'"
  }
  # aws_iam_role_policy.artifact_store_access_for_environment_codepipeline.policy cannot be tested on a plan
  assert {
    condition     = aws_iam_role_policy.artifact_store_access_for_environment_codebuild.name == "my-app-my-pipeline-artifact-store-access-for-environment-codebuild"
    error_message = "Should be: 'my-app-artifact-store-access-for-environment-codebuild'"
  }
  assert {
    condition     = aws_iam_role_policy.artifact_store_access_for_environment_codebuild.role == "my-app-my-pipeline-environment-pipeline-codebuild"
    error_message = "Should be: 'my-app-my-pipeline-environment-pipeline-codebuild'"
  }
  # aws_iam_role_policy.artifact_store_access_for_environment_codebuild.policy cannot be tested on a plan
  assert {
    condition     = aws_iam_role_policy.log_access_for_environment_codebuild.name == "my-app-my-pipeline-log-access-for-environment-codebuild"
    error_message = "Should be: 'my-app-log-access-for-environment-codebuild'"
  }
  assert {
    condition     = aws_iam_role_policy.log_access_for_environment_codebuild.role == "my-app-my-pipeline-environment-pipeline-codebuild"
    error_message = "Should be: 'my-app-my-pipeline-environment-pipeline-codebuild'"
  }
  # aws_iam_role_policy.log_access_for_environment_codebuild.policy cannot be tested on a plan
  assert {
    condition     = aws_iam_role_policy.state_bucket_access_for_environment_codebuild.name == "my-app-my-pipeline-state-bucket-access-for-environment-codebuild"
    error_message = "Should be: 'my-app-state-bucket-access-for-environment-codebuild'"
  }
  assert {
    condition     = aws_iam_role_policy.state_bucket_access_for_environment_codebuild.role == "my-app-my-pipeline-environment-pipeline-codebuild"
    error_message = "Should be: 'my-app-my-pipeline-environment-pipeline-codebuild'"
  }
  # aws_iam_role_policy.state_bucket_access_for_environment_codebuild.policy cannot be tested on a plan
  assert {
    condition     = aws_iam_role_policy.state_kms_key_access_for_environment_codebuild.name == "my-app-my-pipeline-state-kms-key-access-for-environment-codebuild"
    error_message = "Should be: 'my-app-state-kms-key-access-for-environment-codebuild'"
  }
  assert {
    condition     = aws_iam_role_policy.state_kms_key_access_for_environment_codebuild.role == "my-app-my-pipeline-environment-pipeline-codebuild"
    error_message = "Should be: 'my-app-my-pipeline-environment-pipeline-codebuild'"
  }
  # aws_iam_role_policy.state_kms_key_access_for_environment_codebuild.policy cannot be tested on a plan
  assert {
    condition     = aws_iam_role_policy.state_dynamo_db_access_for_environment_codebuild.name == "my-app-my-pipeline-state-dynamo-db-access-for-environment-codebuild"
    error_message = "Should be: 'my-app-state-dynamo-db-access-for-environment-codebuild'"
  }
  assert {
    condition     = aws_iam_role_policy.state_dynamo_db_access_for_environment_codebuild.role == "my-app-my-pipeline-environment-pipeline-codebuild"
    error_message = "Should be: 'my-app-my-pipeline-environment-pipeline-codebuild'"
  }
  # aws_iam_role_policy.state_dynamo_db_access_for_environment_codebuild.policy cannot be tested on a plan
  assert {
    condition     = aws_iam_role_policy.ec2_read_access_for_environment_codebuild.name == "my-app-my-pipeline-ec2-read-access-for-environment-codebuild"
    error_message = "Should be: 'my-app-ec2-read-access-for-environment-codebuild'"
  }
  assert {
    condition     = aws_iam_role_policy.ec2_read_access_for_environment_codebuild.role == "my-app-my-pipeline-environment-pipeline-codebuild"
    error_message = "Should be: 'my-app-my-pipeline-environment-pipeline-codebuild'"
  }
  # aws_iam_role_policy.ec2_read_access_for_environment_codebuild.policy cannot be tested on a plan
  assert {
    condition     = aws_iam_role_policy.ssm_read_access_for_environment_codebuild.name == "my-app-my-pipeline-ssm-read-access-for-environment-codebuild"
    error_message = "Should be: 'my-app-ssm-read-access-for-environment-codebuild'"
  }
  assert {
    condition     = aws_iam_role_policy.ssm_read_access_for_environment_codebuild.role == "my-app-my-pipeline-environment-pipeline-codebuild"
    error_message = "Should be: 'my-app-my-pipeline-environment-pipeline-codebuild'"
  }
  # aws_iam_role_policy.ssm_read_access_for_environment_codebuild.policy cannot be tested on a plan
  assert {
    condition     = aws_iam_role_policy.dns_account_assume_role_for_environment_codebuild.name == "my-app-my-pipeline-dns-account-assume-role-for-environment-codebuild"
    error_message = "Should be: 'my-app-dns-account-assume-role-for-environment-codebuild'"
  }
  assert {
    condition     = aws_iam_role_policy.dns_account_assume_role_for_environment_codebuild.role == "my-app-my-pipeline-environment-pipeline-codebuild"
    error_message = "Should be: 'my-app-my-pipeline-environment-pipeline-codebuild'"
  }
  # aws_iam_role_policy.dns_account_assume_role_for_environment_codebuild.policy cannot be tested on a plan
  assert {
    condition     = aws_iam_policy.load_balancer.name == "my-app-my-pipeline-pipeline-load-balancer-access"
    error_message = "Unexpected name"
  }
  assert {
    condition     = aws_iam_policy.load_balancer.path == "/my-app/codebuild/"
    error_message = "Unexpected path"
  }
  assert {
    condition     = aws_iam_policy.load_balancer.description == "Allow my-app codebuild job to access load-balancer resources"
    error_message = "Unexpected description"
  }
  assert {
    condition     = aws_iam_policy.load_balancer.policy == "{\"Sid\": \"LoadBalancer\"}"
    error_message = "Unexpected policy"
  }
  assert {
    condition     = aws_iam_role_policy.certificate_for_environment_codebuild.name == "my-app-my-pipeline-certificate-for-environment-codebuild"
    error_message = "Should be: 'my-app-certificate-for-environment-codebuild'"
  }
  assert {
    condition     = aws_iam_role_policy.certificate_for_environment_codebuild.role == "my-app-my-pipeline-environment-pipeline-codebuild"
    error_message = "Should be: 'my-app-my-pipeline-environment-pipeline-codebuild'"
  }
  # aws_iam_role_policy.certificate_for_environment_codebuild.policy cannot be tested on a plan
  assert {
    condition     = aws_iam_role_policy.security_group_for_environment_codebuild.name == "my-app-my-pipeline-security-group-for-environment-codebuild"
    error_message = "Should be: 'my-app-security-group-for-environment-codebuild'"
  }
  assert {
    condition     = aws_iam_role_policy.security_group_for_environment_codebuild.role == "my-app-my-pipeline-environment-pipeline-codebuild"
    error_message = "Should be: 'my-app-my-pipeline-environment-pipeline-codebuild'"
  }
  # aws_iam_role_policy.security_group_for_environment_codebuild.policy cannot be tested on a plan
  assert {
    condition     = aws_iam_role_policy.ssm_parameter_for_environment_codebuild.name == "my-app-my-pipeline-ssm-parameter-for-environment-codebuild"
    error_message = "Should be: 'my-app-ssm-parameter-for-environment-codebuild'"
  }
  assert {
    condition     = aws_iam_role_policy.ssm_parameter_for_environment_codebuild.role == "my-app-my-pipeline-environment-pipeline-codebuild"
    error_message = "Should be: 'my-app-my-pipeline-environment-pipeline-codebuild'"
  }
  # aws_iam_role_policy.ssm_parameter_for_environment_codebuild.policy cannot be tested on a plan
  assert {
    condition     = aws_iam_role_policy.cloudwatch_for_environment_codebuild.name == "my-app-my-pipeline-cloudwatch-for-environment-codebuild"
    error_message = "Should be: 'my-app-cloudwatch-for-environment-codebuild'"
  }
  assert {
    condition     = aws_iam_role_policy.cloudwatch_for_environment_codebuild.role == "my-app-my-pipeline-environment-pipeline-codebuild"
    error_message = "Should be: 'my-app-my-pipeline-environment-pipeline-codebuild'"
  }
  # aws_iam_role_policy.cloudwatch_for_environment_codebuild.policy cannot be tested on a plan
  assert {
    condition     = aws_iam_role_policy.logs_for_environment_codebuild.name == "my-app-my-pipeline-logs-for-environment-codebuild"
    error_message = "Should be: 'my-app-logs-for-environment-codebuild'"
  }
  assert {
    condition     = aws_iam_role_policy.logs_for_environment_codebuild.role == "my-app-my-pipeline-environment-pipeline-codebuild"
    error_message = "Should be: 'my-app-my-pipeline-environment-pipeline-codebuild'"
  }
  # aws_iam_role_policy.logs_for_environment_codebuild.policy cannot be tested on a plan

  assert {
    condition     = aws_iam_role_policy.kms_key_for_environment_codebuild.name == "my-app-my-pipeline-kms-key-for-environment-codebuild"
    error_message = "Should be: 'my-app-kms-key-for-environment-codebuild'"
  }
  assert {
    condition     = aws_iam_role_policy.kms_key_for_environment_codebuild.role == "my-app-my-pipeline-environment-pipeline-codebuild"
    error_message = "Should be: 'my-app-my-pipeline-environment-pipeline-codebuild'"
  }
  # aws_iam_role_policy.kms_key_for_environment_codebuild.policy cannot be tested on a plan
  assert {
    condition     = aws_iam_policy.redis.name == "my-app-my-pipeline-pipeline-redis-access"
    error_message = "Unexpected name"
  }
  assert {
    condition     = aws_iam_policy.redis.path == "/my-app/codebuild/"
    error_message = "Unexpected path"
  }
  assert {
    condition     = aws_iam_policy.redis.description == "Allow my-app codebuild job to access redis resources"
    error_message = "Unexpected description"
  }
  assert {
    condition     = aws_iam_policy.redis.policy == "{\"Sid\": \"Redis\"}"
    error_message = "Unexpected policy"
  }
  assert {
    condition     = aws_iam_policy.postgres.name == "my-app-my-pipeline-pipeline-postgres-access"
    error_message = "Unexpected name"
  }
  assert {
    condition     = aws_iam_policy.postgres.path == "/my-app/codebuild/"
    error_message = "Unexpected path"
  }
  assert {
    condition     = aws_iam_policy.postgres.description == "Allow my-app codebuild job to access postgres resources"
    error_message = "Unexpected description"
  }
  assert {
    condition     = aws_iam_policy.postgres.policy == "{\"Sid\": \"Postgres\"}"
    error_message = "Unexpected policy"
  }
  assert {
    condition     = aws_iam_policy.s3.name == "my-app-my-pipeline-pipeline-s3-access"
    error_message = "Unexpected name"
  }
  assert {
    condition     = aws_iam_policy.s3.path == "/my-app/codebuild/"
    error_message = "Unexpected path"
  }
  assert {
    condition     = aws_iam_policy.s3.description == "Allow my-app codebuild job to access s3 resources"
    error_message = "Unexpected description"
  }
  assert {
    condition     = aws_iam_policy.s3.policy == "{\"Sid\": \"S3\"}"
    error_message = "Unexpected policy"
  }
  assert {
    condition     = aws_iam_policy.opensearch.name == "my-app-my-pipeline-pipeline-opensearch-access"
    error_message = "Unexpected name"
  }
  assert {
    condition     = aws_iam_policy.opensearch.path == "/my-app/codebuild/"
    error_message = "Unexpected path"
  }
  assert {
    condition     = aws_iam_policy.opensearch.description == "Allow my-app codebuild job to access opensearch resources"
    error_message = "Unexpected description"
  }
  assert {
    condition     = aws_iam_policy.opensearch.policy == "{\"Sid\": \"OpenSearch\"}"
    error_message = "Unexpected policy"
  }
  assert {
    condition     = aws_iam_policy.cloudformation.name == "my-app-my-pipeline-pipeline-cloudformation-access"
    error_message = "Unexpected name"
  }
  assert {
    condition     = aws_iam_policy.cloudformation.path == "/my-app/codebuild/"
    error_message = "Unexpected path"
  }
  assert {
    condition     = aws_iam_policy.cloudformation.description == "Allow my-app codebuild job to access cloudformation resources"
    error_message = "Unexpected description"
  }
  assert {
    condition     = aws_iam_policy.cloudformation.policy == "{\"Sid\": \"CloudFormation\"}"
    error_message = "Unexpected policy"
  }
  assert {
    condition     = aws_iam_role_policy.copilot_assume_role_for_environment_codebuild.name == "my-app-my-pipeline-copilot-assume-role-for-environment-codebuild"
    error_message = "Should be: 'my-app-copilot-assume-role-for-environment-codebuild'"
  }
  assert {
    condition     = aws_iam_role_policy.copilot_assume_role_for_environment_codebuild.role == "my-app-my-pipeline-environment-pipeline-codebuild"
    error_message = "Should be: 'my-app-my-pipeline-environment-pipeline-codebuild'"
  }
  # aws_iam_role_policy.copilot_assume_role_for_environment_codebuild.policy cannot be tested on a plan

  assert {
    condition     = aws_iam_policy.iam.name == "my-app-my-pipeline-pipeline-iam"
    error_message = "Should be: my-app-my-pipeline-pipeline-iam"
  }

  # IAM Policy not currently computed by mock due to https://github.com/hashicorp/terraform-provider-aws/issues/36700. Using override
  assert {
    condition     = aws_iam_policy.iam.policy == "{\"Sid\": \"IAM\"}"
    error_message = "Unexpected policy"
  }

  assert {
    condition     = aws_iam_policy.codepipeline.policy == "{\"Sid\": \"codepipeline\"}"
    error_message = "Unexpected policy"
  }
}

run "test_artifact_store" {
  command = plan

  # artifact-store S3 bucket.
  assert {
    condition     = module.artifact_store.bucket_name == "my-app-my-pipeline-environment-pipeline-artifact-store"
    error_message = "Should be: my-app-my-pipeline-environment-pipeline-artifact-store"
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
    condition     = aws_codepipeline.environment_pipeline.stage[2].action[0].output_artifacts[0] == "dev_terraform_plan"
    error_message = "Output artifacts incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[2].action[0].version == "1"
    error_message = "Action Version incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[2].action[0].configuration.ProjectName == "my-app-my-pipeline-environment-pipeline-plan"
    error_message = "Configuration ProjectName incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[2].action[0].configuration.PrimarySource == "build_output"
    error_message = "Configuration PrimarySource incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[2].action[0].configuration.EnvironmentVariables == "[{\"name\":\"APPLICATION\",\"value\":\"my-app\"},{\"name\":\"ENVIRONMENT\",\"value\":\"dev\"},{\"name\":\"COPILOT_PROFILE\",\"value\":\"sandbox\"},{\"name\":\"SLACK_CHANNEL_ID\",\"type\":\"PARAMETER_STORE\",\"value\":\"/codebuild/slack_pipeline_notifications_channel\"},{\"name\":\"SLACK_REF\",\"value\":\"#{slack.SLACK_REF}\"},{\"name\":\"NEEDS_APPROVAL\",\"value\":\"no\"}]"
    error_message = "Configuration Env Vars incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[2].action[0].namespace == "dev-plan"
    error_message = "Input artifacts incorrect"
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
    condition     = length(aws_codepipeline.environment_pipeline.stage[3].action[0].input_artifacts) == 1
    error_message = "Input artifacts incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[3].action[0].input_artifacts[0] == "dev_terraform_plan"
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
    condition     = aws_codepipeline.environment_pipeline.stage[3].action[0].configuration.ProjectName == "my-app-my-pipeline-environment-pipeline-apply"
    error_message = "Configuration ProjectName incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[3].action[0].configuration.PrimarySource == "dev_terraform_plan"
    error_message = "Configuration PrimarySource incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[3].action[0].configuration.EnvironmentVariables == "[{\"name\":\"ENVIRONMENT\",\"value\":\"dev\"},{\"name\":\"SLACK_CHANNEL_ID\",\"type\":\"PARAMETER_STORE\",\"value\":\"/codebuild/slack_pipeline_notifications_channel\"},{\"name\":\"SLACK_REF\",\"value\":\"#{slack.SLACK_REF}\"},{\"name\":\"VPC\",\"value\":\"platform-sandbox-dev\"}]"
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
    condition     = aws_codepipeline.environment_pipeline.stage[4].action[0].output_artifacts[0] == "prod_terraform_plan"
    error_message = "Output artifacts incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[4].action[0].version == "1"
    error_message = "Action Version incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[4].action[0].configuration.ProjectName == "my-app-my-pipeline-environment-pipeline-plan"
    error_message = "Configuration ProjectName incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[4].action[0].configuration.PrimarySource == "build_output"
    error_message = "Configuration PrimarySource incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[4].action[0].configuration.EnvironmentVariables == "[{\"name\":\"APPLICATION\",\"value\":\"my-app\"},{\"name\":\"ENVIRONMENT\",\"value\":\"prod\"},{\"name\":\"COPILOT_PROFILE\",\"value\":\"prod\"},{\"name\":\"SLACK_CHANNEL_ID\",\"type\":\"PARAMETER_STORE\",\"value\":\"/codebuild/slack_pipeline_notifications_channel\"},{\"name\":\"SLACK_REF\",\"value\":\"#{slack.SLACK_REF}\"},{\"name\":\"NEEDS_APPROVAL\",\"value\":\"yes\"}]"
    error_message = "Configuration Env Vars incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[4].action[0].namespace == "prod-plan"
    error_message = "Namespace incorrect"
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
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[5].action[0].configuration.ExternalEntityLink == "https://${data.aws_region.current.name}.console.aws.amazon.com/codesuite/codebuild/${data.aws_caller_identity.current.account_id}/projects/my-app-my-pipeline-environment-pipeline-plan/build/#{prod-plan.BUILD_ID}"
    error_message = "Configuration ExternalEntityLink incorrect"
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
    condition     = length(aws_codepipeline.environment_pipeline.stage[6].action[0].input_artifacts) == 1
    error_message = "Input artifacts incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[6].action[0].input_artifacts[0] == "prod_terraform_plan"
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
    condition     = aws_codepipeline.environment_pipeline.stage[6].action[0].configuration.ProjectName == "my-app-my-pipeline-environment-pipeline-apply"
    error_message = "Configuration ProjectName incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[6].action[0].configuration.PrimarySource == "prod_terraform_plan"
    error_message = "Configuration PrimarySource incorrect"
  }
  assert {
    condition     = aws_codepipeline.environment_pipeline.stage[6].action[0].configuration.EnvironmentVariables == "[{\"name\":\"ENVIRONMENT\",\"value\":\"prod\"},{\"name\":\"SLACK_CHANNEL_ID\",\"type\":\"PARAMETER_STORE\",\"value\":\"/codebuild/slack_pipeline_notifications_channel\"},{\"name\":\"SLACK_REF\",\"value\":\"#{slack.SLACK_REF}\"},{\"name\":\"VPC\",\"value\":\"platform-sandbox-prod\"}]"
    error_message = "Configuration Env Vars incorrect"
  }
}




