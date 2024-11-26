mock_provider "aws" {}

override_data {
  target = data.aws_iam_policy_document.assume_codebuild_role
  values = {
    json = "{\"Sid\": \"AssumeCodebuildRole\"}"
  }
}

override_data {
  target = data.aws_iam_policy_document.log_access_for_codebuild
  values = {
    json = "{\"Sid\": \"CodeBuildLogs\"}"
  }
}

override_data {
  target = data.aws_iam_policy_document.ecr_access_for_codebuild_images
  values = {
    json = "{\"Sid\": \"CodeBuildImageECRAccess\"}"
  }
}

override_data {
  target = data.aws_iam_policy_document.codestar_connection_access
  values = {
    json = "{\"Sid\": \"CodeStarConnectionAccess\"}"
  }
}

override_data {
  target = data.aws_iam_policy_document.assume_codepipeline_role
  values = {
    json = "{\"Sid\": \"AssumeCodepipelineRole\"}"
  }
}

override_data {
  target = data.aws_iam_policy_document.assume_event_bridge_policy
  values = {
    json = "{\"Sid\": \"AssumeEventBridge\"}"
  }
}

override_data {
  target = data.aws_iam_policy_document.event_bridge_pipeline_trigger
  values = {
    json = "{\"Sid\": \"EventBridgePipelineTrigger\"}"
  }
}

override_data {
  target = data.aws_iam_policy_document.assume_environment_deploy_role
  values = {
    json = "{\"Sid\": \"AssumeEnvironmentDeployRole\"}"
  }
}

variables {
  env_config = {
    "*" = {
      accounts = {
        deploy = {
          name = "sandbox"
          id   = "000123456789"
        }
      }
    },
    "dev"     = null,
    "staging" = null,
    "prod" = {
      accounts = {
        deploy = {
          name = "prod"
          id   = "123456789000"
        }
      }
    }
  }
  application               = "my-app"
  codebase                  = "my-codebase"
  repository                = "my-repository"
  additional_ecr_repository = "my-additional-repository"
  services = [
    {
      "run_group_1" : [
        "service-1"
      ]
    },
    {
      "run_group_2" : [
        "service-2"
      ]
    }
  ]
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
  expected_tags = {
    application         = "my-app"
    copilot-application = "my-app"
    managed-by          = "DBT Platform - Terraform"
  }
  expected_ecr_tags = {
    copilot-pipeline    = "my-codebase"
    copilot-application = "my-app"
  }
}

run "test_ecr" {
  command = plan

  assert {
    condition     = aws_ecr_repository.this.name == "my-app/my-codebase"
    error_message = "Should be: my-app/my-codebase"
  }
  assert {
    condition     = jsonencode(aws_ecr_repository.this.tags) == jsonencode(var.expected_ecr_tags)
    error_message = "Should be: ${jsonencode(var.expected_ecr_tags)}"
  }
}

run "test_artifact_store" {
  command = plan

  assert {
    condition     = aws_s3_bucket.artifact_store.bucket == "my-app-my-codebase-codebase-pipeline-artifact-store"
    error_message = "Should be: my-app-my-codebase-codebase-pipeline-artifact-store"
  }
  assert {
    condition     = aws_kms_alias.artifact_store_kms_alias.name == "alias/my-app-my-codebase-codebase-pipeline-artifact-store-key"
    error_message = "Should be: alias/my-app-my-codebase-codebase-pipeline-artifact-store-key"
  }
  assert {
    condition     = [for el in data.aws_iam_policy_document.artifact_store_bucket_policy.statement[0].condition : el.variable][0] == "aws:SecureTransport"
    error_message = "Should be: aws:SecureTransport"
  }
  assert {
    condition     = data.aws_iam_policy_document.artifact_store_bucket_policy.statement[0].effect == "Deny"
    error_message = "Should be: Deny"
  }
  assert {
    condition     = [for el in data.aws_iam_policy_document.artifact_store_bucket_policy.statement[0].actions : el][0] == "s3:*"
    error_message = "Should be: s3:*"
  }
  assert {
    condition     = [for el in data.aws_iam_policy_document.artifact_store_bucket_policy.statement[1].principals : el.type][0] == "AWS"
    error_message = "Should be: AWS"
  }
  assert {
    condition     = flatten([for el in data.aws_iam_policy_document.artifact_store_bucket_policy.statement[1].principals : el.identifiers]) == ["arn:aws:iam::000123456789:role/my-app-dev-codebase-pipeline-deploy-role", "arn:aws:iam::000123456789:role/my-app-staging-codebase-pipeline-deploy-role", "arn:aws:iam::123456789000:role/my-app-prod-codebase-pipeline-deploy-role"]
    error_message = "Bucket policy principals incorrect"
  }
  assert {
    condition     = [for el in data.aws_iam_policy_document.artifact_store_bucket_policy.statement[1].actions : el][0] == "s3:*"
    error_message = "Should be: s3:*"
  }
}

run "test_codebuild_images" {
  command = plan

  assert {
    condition     = aws_codebuild_project.codebase_image_build.name == "my-app-my-codebase-codebase-image-build"
    error_message = "Should be: my-app-my-codebase-codebase-image-build"
  }
  assert {
    condition     = aws_codebuild_project.codebase_image_build.description == "Publish images on push to my-repository"
    error_message = "Should be: 'Publish images on push to my-repository'"
  }
  assert {
    condition     = aws_codebuild_project.codebase_image_build.build_timeout == 30
    error_message = "Should be: 30"
  }
  assert {
    condition     = one(aws_codebuild_project.codebase_image_build.artifacts).type == "NO_ARTIFACTS"
    error_message = "Should be: 'NO_ARTIFACTS'"
  }
  assert {
    condition     = one(aws_codebuild_project.codebase_image_build.cache).type == "LOCAL"
    error_message = "Should be: 'LOCAL'"
  }
  assert {
    condition     = one(aws_codebuild_project.codebase_image_build.cache).modes[0] == "LOCAL_DOCKER_LAYER_CACHE"
    error_message = "Should be: 'LOCAL_DOCKER_LAYER_CACHE'"
  }
  assert {
    condition     = one(aws_codebuild_project.codebase_image_build.environment).compute_type == "BUILD_GENERAL1_SMALL"
    error_message = "Should be: 'BUILD_GENERAL1_SMALL'"
  }
  assert {
    condition     = one(aws_codebuild_project.codebase_image_build.environment).image == "public.ecr.aws/uktrade/ci-image-builder:tag-latest"
    error_message = "Should be: 'public.ecr.aws/uktrade/ci-image-builder:tag-latest'"
  }
  assert {
    condition     = one(aws_codebuild_project.codebase_image_build.environment).environment_variable[1].name == "ECR_REPOSITORY"
    error_message = "Should be: 'ECR_REPOSITORY'"
  }
  assert {
    condition     = one(aws_codebuild_project.codebase_image_build.environment).environment_variable[1].value == "my-app/my-codebase"
    error_message = "Should be: 'my-app/my-codebase'"
  }
  assert {
    condition     = one(aws_codebuild_project.codebase_image_build.environment).environment_variable[3].name == "ADDITIONAL_ECR_REPOSITORY"
    error_message = "Should be: 'ADDITIONAL_ECR_REPOSITORY'"
  }
  assert {
    condition     = one(aws_codebuild_project.codebase_image_build.environment).environment_variable[3].value == "my-additional-repository"
    error_message = "Should be: 'my-additional-repository'"
  }
  assert {
    condition = aws_codebuild_project.codebase_image_build.logs_config[0].cloudwatch_logs[
      0
    ].group_name == "codebuild/my-app-my-codebase-codebase-image-build/log-group"
    error_message = "Should be: 'codebuild/my-app-my-codebase-codebase-image-build/log-group'"
  }
  assert {
    condition = aws_codebuild_project.codebase_image_build.logs_config[0].cloudwatch_logs[
      0
    ].stream_name == "codebuild/my-app-my-codebase-codebase-image-build/log-stream"
    error_message = "Should be: 'codebuild/my-app-my-codebase-codebase-image-build/log-stream'"
  }
  assert {
    condition     = one(aws_codebuild_project.codebase_image_build.source).type == "GITHUB"
    error_message = "Should be: 'GITHUB'"
  }
  assert {
    condition     = one(aws_codebuild_project.codebase_image_build.source).location == "https://github.com/my-repository.git"
    error_message = "Should be: 'https://github.com/my-repository.git'"
  }
  assert {
    condition     = length(regexall(".*/work/cli build.*", aws_codebuild_project.codebase_image_build.source[0].buildspec)) > 0
    error_message = "Should contain: '/work/cli build'"
  }
  assert {
    condition     = jsonencode(aws_codebuild_project.codebase_image_build.tags) == jsonencode(var.expected_tags)
    error_message = "Should be: ${jsonencode(var.expected_tags)}"
  }

  # Cloudwatch config:
  assert {
    condition     = aws_cloudwatch_log_group.codebase_image_build.name == "codebuild/my-app-my-codebase-codebase-image-build/log-group"
    error_message = "Should be: 'codebuild/my-app-my-codebase-codebase-image-build/log-group'"
  }
  assert {
    condition     = aws_cloudwatch_log_group.codebase_image_build.retention_in_days == 90
    error_message = "Should be: 90"
  }
  assert {
    condition     = aws_cloudwatch_log_stream.codebase_image_build.name == "codebuild/my-app-my-codebase-codebase-image-build/log-stream"
    error_message = "Should be: 'codebuild/my-app-my-codebase-codebase-image-build/log-stream'"
  }
  assert {
    condition     = aws_cloudwatch_log_stream.codebase_image_build.log_group_name == "codebuild/my-app-my-codebase-codebase-image-build/log-group"
    error_message = "Should be: 'codebuild/my-app-my-codebase-codebase-image-build/log-group'"
  }

  # Webhook config:
  assert {
    condition     = aws_codebuild_webhook.codebuild_webhook.project_name == "my-app-my-codebase-codebase-image-build"
    error_message = "Should be: 'my-app-my-codebase-codebase-image-build'"
  }
  assert {
    condition     = aws_codebuild_webhook.codebuild_webhook.build_type == "BUILD"
    error_message = "Should be: 'BUILD'"
  }

  assert {
    condition     = length(aws_codebuild_webhook.codebuild_webhook.filter_group) == 2
    error_message = "Should be: 2"
  }
  assert {
    condition = [
      for el in aws_codebuild_webhook.codebuild_webhook.filter_group : true
      if[for filter in el.filter : true if filter.type == "EVENT" && filter.pattern == "PUSH"][0] == true
      ][
      0
    ] == true
    error_message = "Should be: type = 'EVENT' and pattern = 'PUSH'"
  }
}

run "test_main_branch_filter" {
  command = plan

  variables {
    pipelines = [
      {
        name   = "main",
        branch = "main",
        environments = [
          { name = "dev" },
          { name = "prod", requires_approval = true }
        ]
      }
    ]
  }

  assert {
    condition = [
      for el in aws_codebuild_webhook.codebuild_webhook.filter_group : true
      if[
        for filter in el.filter : true
        if filter.type == "HEAD_REF" && filter.pattern == "^refs/heads/main$"
        ][
        0
      ] == true
      ][
      0
    ] == true
    error_message = "Should be: type = 'HEAD_REF' and pattern = '^refs/heads/main$'"
  }
}

run "test_tagged_branch_filter" {
  command = plan

  variables {
    pipelines = [
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

  assert {
    condition = [
      for el in aws_codebuild_webhook.codebuild_webhook.filter_group : true
      if[
        for filter in el.filter : true
        if filter.type == "HEAD_REF" && filter.pattern == "^refs/tags/.*"
        ][
        0
      ] == true
      ][
      0
    ] == true
    error_message = "Should be: type = 'HEAD_REF' and pattern = '^refs/tags/.*'"
  }
}

run "test_iam" {
  command = plan

  # CodeBuild image build
  assert {
    condition     = aws_iam_role.codebase_image_build.name == "my-app-my-codebase-codebase-image-build"
    error_message = "Should be: 'my-app-my-codebase-codebase-image-build'"
  }
  assert {
    condition     = aws_iam_role.codebase_image_build.assume_role_policy == "{\"Sid\": \"AssumeCodebuildRole\"}"
    error_message = "Should be: {\"Sid\": \"AssumeCodebuildRole\"}"
  }
  assert {
    condition     = jsonencode(aws_iam_role.codebase_image_build.tags) == jsonencode(var.expected_tags)
    error_message = "Should be: ${jsonencode(var.expected_tags)}"
  }
  assert {
    condition     = data.aws_iam_policy_document.assume_codebuild_role.statement[0].effect == "Allow"
    error_message = "Should be: Allow"
  }
  assert {
    condition     = one(data.aws_iam_policy_document.assume_codebuild_role.statement[0].actions) == "sts:AssumeRole"
    error_message = "Should be: sts:AssumeRole"
  }
  assert {
    condition     = one(data.aws_iam_policy_document.assume_codebuild_role.statement[0].principals).type == "Service"
    error_message = "Should be: Service"
  }
  assert {
    condition     = contains(one(data.aws_iam_policy_document.assume_codebuild_role.statement[0].principals).identifiers, "codebuild.amazonaws.com")
    error_message = "Should contain: codebuild.amazonaws.com"
  }
  assert {
    condition     = aws_iam_role_policy.log_access_for_codebuild_images.name == "my-app-my-codebase-log-access-for-codebuild-images"
    error_message = "Should be: 'my-app-my-codebase-log-access-for-codebuild-images'"
  }
  assert {
    condition     = aws_iam_role_policy.log_access_for_codebuild_images.role == "my-app-my-codebase-codebase-image-build"
    error_message = "Should be: 'my-app-my-codebase-codebase-image-build'"
  }
  assert {
    condition     = data.aws_iam_policy_document.log_access_for_codebuild.statement[0].effect == "Allow"
    error_message = "Should be: Allow"
  }
  assert {
    condition     = data.aws_iam_policy_document.log_access_for_codebuild.statement[0].actions == toset(["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents", "logs:TagLogGroup"])
    error_message = "Unexpected actions"
  }
  assert {
    condition     = data.aws_iam_policy_document.log_access_for_codebuild.statement[1].effect == "Allow"
    error_message = "Should be: Allow"
  }
  assert {
    condition = data.aws_iam_policy_document.log_access_for_codebuild.statement[1].actions == toset([
      "codebuild:CreateReportGroup",
      "codebuild:CreateReport",
      "codebuild:UpdateReport",
      "codebuild:BatchPutTestCases",
      "codebuild:BatchPutCodeCoverages"
    ])
    error_message = "Unexpected actions"
  }
  assert {
    condition = data.aws_iam_policy_document.log_access_for_codebuild.statement[1].resources == toset([
      "arn:aws:codebuild:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:report-group/my-app-my-codebase-*-codebase-deploy-manifests-*",
      "arn:aws:codebuild:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:report-group/my-app-my-codebase-codebase-image-build-*",
      "arn:aws:codebuild:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:report-group/pipeline-my-app-*"
    ])
    error_message = "Unexpected resources"
  }
  assert {
    condition     = aws_iam_role_policy.ecr_access_for_codebuild_images.name == "my-app-my-codebase-ecr-access-for-codebuild-images"
    error_message = "Should be: 'my-app-my-codebase-ecr-access-for-codebuild-images'"
  }
  assert {
    condition     = aws_iam_role_policy.ecr_access_for_codebuild_images.role == "my-app-my-codebase-codebase-image-build"
    error_message = "Should be: 'my-app-my-codebase-codebase-image-build'"
  }
  assert {
    condition     = data.aws_iam_policy_document.ecr_access_for_codebuild_images.statement[0].effect == "Allow"
    error_message = "Should be: Allow"
  }
  assert {
    condition     = one(data.aws_iam_policy_document.ecr_access_for_codebuild_images.statement[0].actions) == "ecr:GetAuthorizationToken"
    error_message = "Unexpected actions"
  }
  assert {
    condition     = one(data.aws_iam_policy_document.ecr_access_for_codebuild_images.statement[0].resources) == "arn:aws:codebuild:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:report-group/pipeline-my-app-*"
    error_message = "Unexpected resources"
  }
  assert {
    condition     = data.aws_iam_policy_document.ecr_access_for_codebuild_images.statement[1].effect == "Allow"
    error_message = "Should be: Allow"
  }
  assert {
    condition = data.aws_iam_policy_document.ecr_access_for_codebuild_images.statement[1].actions == toset([
      "ecr:GetAuthorizationToken",
      "ecr-public:GetAuthorizationToken",
      "sts:GetServiceBearerToken"
    ])
    error_message = "Unexpected actions"
  }
  assert {
    condition     = one(data.aws_iam_policy_document.ecr_access_for_codebuild_images.statement[1].resources) == "*"
    error_message = "Unexpected resources"
  }
  assert {
    condition     = data.aws_iam_policy_document.ecr_access_for_codebuild_images.statement[2].effect == "Allow"
    error_message = "Should be: Allow"
  }
  assert {
    condition = data.aws_iam_policy_document.ecr_access_for_codebuild_images.statement[2].actions == toset([
      "ecr-public:DescribeImageScanFindings",
      "ecr-public:GetLifecyclePolicyPreview",
      "ecr-public:GetDownloadUrlForLayer",
      "ecr-public:BatchGetImage",
      "ecr-public:DescribeImages",
      "ecr-public:ListTagsForResource",
      "ecr-public:BatchCheckLayerAvailability",
      "ecr-public:GetLifecyclePolicy",
      "ecr-public:GetRepositoryPolicy",
      "ecr-public:PutImage",
      "ecr-public:InitiateLayerUpload",
      "ecr-public:UploadLayerPart",
      "ecr-public:CompleteLayerUpload",
      "ecr-public:BatchDeleteImage",
      "ecr-public:DescribeRepositories",
      "ecr-public:ListImages"
    ])
    error_message = "Unexpected actions"
  }
  assert {
    condition     = one(data.aws_iam_policy_document.ecr_access_for_codebuild_images.statement[2].resources) == "arn:aws:ecr-public::${data.aws_caller_identity.current.account_id}:repository/*"
    error_message = "Unexpected resources"
  }
  assert {
    condition     = data.aws_iam_policy_document.ecr_access_for_codebuild_images.statement[3].effect == "Allow"
    error_message = "Should be: Allow"
  }
  assert {
    condition = data.aws_iam_policy_document.ecr_access_for_codebuild_images.statement[3].actions == toset([
      "ecr:DescribeImageScanFindings",
      "ecr:GetLifecyclePolicyPreview",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:DescribeImages",
      "ecr:ListTagsForResource",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetLifecyclePolicy",
      "ecr:GetRepositoryPolicy",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:BatchDeleteImage",
      "ecr:DescribeRepositories",
      "ecr:ListImages"
    ])
    error_message = "Unexpected actions"
  }
  assert {
    condition     = aws_iam_role_policy.codestar_connection_access.name == "codestar-connection-policy"
    error_message = "Should be: 'codestar-connection-policy'"
  }
  assert {
    condition     = aws_iam_role_policy.codestar_connection_access.role == "my-app-my-codebase-codebase-image-build"
    error_message = "Should be: 'my-app-my-codebase-codebase-image-build'"
  }
  assert {
    condition     = data.aws_iam_policy_document.codestar_connection_access.statement[0].effect == "Allow"
    error_message = "Should be: Allow"
  }
  assert {
    condition = data.aws_iam_policy_document.codestar_connection_access.statement[0].actions == toset([
      "codestar-connections:GetConnectionToken",
      "codestar-connections:UseConnection"
    ])
    error_message = "Unexpected actions"
  }
  assert {
    condition     = aws_iam_role_policy_attachment.ssm_access.role == "my-app-my-codebase-codebase-image-build"
    error_message = "Should be: 'my-app-my-codebase-codebase-image-build'"
  }
  assert {
    condition     = aws_iam_role_policy_attachment.ssm_access.policy_arn == "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
    error_message = "Should be: 'arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess'"
  }

  # CodeBuild deploy manifests
  assert {
    condition     = aws_iam_role.codebuild_manifests.name == "my-app-my-codebase-codebase-codebuild-manifests"
    error_message = "Should be: 'my-app-my-codebase-codebase-codebuild-manifests'"
  }
  assert {
    condition     = aws_iam_role.codebuild_manifests.assume_role_policy == "{\"Sid\": \"AssumeCodebuildRole\"}"
    error_message = "Should be: {\"Sid\": \"AssumeCodebuildRole\"}"
  }
  assert {
    condition     = jsonencode(aws_iam_role.codebuild_manifests.tags) == jsonencode(var.expected_tags)
    error_message = "Should be: ${jsonencode(var.expected_tags)}"
  }
  assert {
    condition     = aws_iam_role_policy.artifact_store_access_for_codebuild_manifests.name == "my-app-my-codebase-artifact-store-access-for-codebuild-manifests"
    error_message = "Should be: 'my-app-my-codebase-artifact-store-access-for-codebuild-manifests'"
  }
  assert {
    condition     = aws_iam_role_policy.artifact_store_access_for_codebuild_manifests.role == "my-app-my-codebase-codebase-codebuild-manifests"
    error_message = "Should be: 'my-app-my-codebase-codebase-codebuild-manifests'"
  }
  assert {
    condition     = data.aws_iam_policy_document.access_artifact_store.statement[0].effect == "Allow"
    error_message = "Should be: Allow"
  }
  assert {
    condition = data.aws_iam_policy_document.access_artifact_store.statement[0].actions == toset([
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObjectAcl",
      "s3:PutObject",
    ])
    error_message = "Unexpected actions"
  }
  assert {
    condition     = data.aws_iam_policy_document.access_artifact_store.statement[1].effect == "Allow"
    error_message = "Should be: Allow"
  }
  assert {
    condition = data.aws_iam_policy_document.access_artifact_store.statement[1].actions == toset([
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
    ])
    error_message = "Unexpected actions"
  }
  assert {
    condition     = one(data.aws_iam_policy_document.access_artifact_store.statement[1].resources) == "*"
    error_message = "Unexpected resources"
  }
  assert {
    condition     = data.aws_iam_policy_document.access_artifact_store.statement[2].effect == "Allow"
    error_message = "Should be: Allow"
  }
  assert {
    condition = data.aws_iam_policy_document.access_artifact_store.statement[2].actions == toset([
      "kms:GenerateDataKey",
      "kms:Decrypt"
    ])
    error_message = "Unexpected actions"
  }
  assert {
    condition     = aws_iam_role_policy.log_access_for_codebuild_manifests.name == "my-app-my-codebase-log-access-for-codebuild-manifests"
    error_message = "Should be: 'my-app-my-codebase-log-access-for-codebuild-manifests'"
  }
  assert {
    condition     = aws_iam_role_policy.log_access_for_codebuild_manifests.role == "my-app-my-codebase-codebase-codebuild-manifests"
    error_message = "Should be: 'my-app-my-codebase-codebase-codebuild-manifests'"
  }
  assert {
    condition     = aws_iam_role_policy.ecs_access_for_codebuild_manifests.name == "my-app-my-codebase-ecs-access-for-codebuild-manifests"
    error_message = "Should be: 'my-app-my-codebase-ecs-access-for-codebuild-manifests'"
  }
  assert {
    condition     = aws_iam_role_policy.ecs_access_for_codebuild_manifests.role == "my-app-my-codebase-codebase-codebuild-manifests"
    error_message = "Should be: 'my-app-my-codebase-codebase-codebuild-manifests'"
  }
  assert {
    condition     = aws_iam_role_policy.ecs_access_for_codebuild_manifests.policy == "{\"Sid\": \"CodeBuildDeployManifestECS\"}"
    error_message = "Should be: {\"Sid\": \"CodeBuildDeployManifestECS\"}"
  }
  assert {
    condition     = data.aws_iam_policy_document.ecs_access_for_codebuild_manifests.statement[0].effect == "Allow"
    error_message = "Should be: Allow"
  }
  assert {
    condition     = one(data.aws_iam_policy_document.ecs_access_for_codebuild_manifests.statement[0].actions) == "ecs:ListServices"
    error_message = "Unexpected actions"
  }
  assert {
    condition     = one(data.aws_iam_policy_document.ecs_access_for_codebuild_manifests.statement[0].resources) == "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:service/my-app-dev/*"
    error_message = "Unexpected resources"
  }
  assert {
    condition     = one(data.aws_iam_policy_document.ecs_access_for_codebuild_manifests.statement[1].resources) == "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:service/my-app-staging/*"
    error_message = "Unexpected resources"
  }
  assert {
    condition     = one(data.aws_iam_policy_document.ecs_access_for_codebuild_manifests.statement[2].resources) == "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:service/my-app-prod/*"
    error_message = "Unexpected resources"
  }

  # CodePipeline
  assert {
    condition     = aws_iam_role.codebase_deploy_pipeline.name == "my-app-my-codebase-codebase-pipeline"
    error_message = "Should be: 'my-app-my-codebase-codebase-pipeline'"
  }
  assert {
    condition     = aws_iam_role.codebase_deploy_pipeline.assume_role_policy == "{\"Sid\": \"AssumeCodepipelineRole\"}"
    error_message = "Should be: {\"Sid\": \"AssumeCodepipelineRole\"}"
  }
  assert {
    condition     = jsonencode(aws_iam_role.codebase_deploy_pipeline.tags) == jsonencode(var.expected_tags)
    error_message = "Should be: ${jsonencode(var.expected_tags)}"
  }
  assert {
    condition     = data.aws_iam_policy_document.assume_codepipeline_role.statement[0].effect == "Allow"
    error_message = "Should be: Allow"
  }
  assert {
    condition     = one(data.aws_iam_policy_document.assume_codepipeline_role.statement[0].actions) == "sts:AssumeRole"
    error_message = "Should be: sts:AssumeRole"
  }
  assert {
    condition     = one(data.aws_iam_policy_document.assume_codepipeline_role.statement[0].principals).type == "Service"
    error_message = "Should be: Service"
  }
  assert {
    condition     = contains(one(data.aws_iam_policy_document.assume_codepipeline_role.statement[0].principals).identifiers, "codepipeline.amazonaws.com")
    error_message = "Should contain: codepipeline.amazonaws.com"
  }
  assert {
    condition     = aws_iam_role_policy.ecr_access_for_codebase_pipeline.name == "my-app-my-codebase-ecr-access-for-codebase-pipeline"
    error_message = "Should be: 'my-app-my-codebase-ecr-access-for-codebase-pipeline'"
  }
  assert {
    condition     = aws_iam_role_policy.ecr_access_for_codebase_pipeline.role == "my-app-my-codebase-codebase-pipeline"
    error_message = "Should be: 'my-app-my-codebase-codebase-pipeline'"
  }
  assert {
    condition     = data.aws_iam_policy_document.ecr_access_for_codebase_pipeline.statement[0].effect == "Allow"
    error_message = "Should be: Allow"
  }
  assert {
    condition     = one(data.aws_iam_policy_document.ecr_access_for_codebase_pipeline.statement[0].actions) == "ecr:DescribeImages"
    error_message = "Unexpected actions"
  }
  assert {
    condition     = aws_iam_role_policy.artifact_store_access_for_codebase_pipeline.name == "my-app-my-codebase-artifact-store-access-for-codebase-pipeline"
    error_message = "Should be: 'my-app-my-codebase-artifact-store-access-for-codebase-pipeline'"
  }
  assert {
    condition     = aws_iam_role_policy.artifact_store_access_for_codebase_pipeline.role == "my-app-my-codebase-codebase-pipeline"
    error_message = "Should be: 'my-app-my-codebase-codebase-pipeline'"
  }
  assert {
    condition     = aws_iam_role_policy.ecs_deploy_access_for_codebase_pipeline.name == "my-app-my-codebase-ecs-deploy-access-for-codebase-pipeline"
    error_message = "Should be: 'my-app-my-codebase-ecs-deploy-access-for-codebase-pipeline'"
  }
  assert {
    condition     = aws_iam_role_policy.ecs_deploy_access_for_codebase_pipeline.role == "my-app-my-codebase-codebase-pipeline"
    error_message = "Should be: 'my-app-my-codebase-codebase-pipeline'"
  }
  assert {
    condition     = aws_iam_role_policy.ecs_deploy_access_for_codebase_pipeline.policy == "{\"Sid\": \"CodePipelineECSDeploy\"}"
    error_message = "Should be: {\"Sid\": \"CodePipelineECSDeploy\"}"
  }
  assert {
    condition     = data.aws_iam_policy_document.ecs_deploy_access_for_codebase_pipeline.statement[0].effect == "Allow"
    error_message = "Should be: Allow"
  }
  assert {
    condition = data.aws_iam_policy_document.ecs_deploy_access_for_codebase_pipeline.statement[0].actions == toset([
      "ecs:UpdateService",
      "ecs:DescribeServices",
      "ecs:TagResource"
    ])
    error_message = "Unexpected actions"
  }
  assert {
    condition = data.aws_iam_policy_document.ecs_deploy_access_for_codebase_pipeline.statement[0].resources == toset([
      "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/my-app-dev",
      "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:service/my-app-dev/*"
    ])
    error_message = "Unexpected resources"
  }
  assert {
    condition     = data.aws_iam_policy_document.ecs_deploy_access_for_codebase_pipeline.statement[1].effect == "Allow"
    error_message = "Should be: Allow"
  }
  assert {
    condition = data.aws_iam_policy_document.ecs_deploy_access_for_codebase_pipeline.statement[1].actions == toset([
      "ecs:UpdateService",
      "ecs:DescribeServices",
      "ecs:TagResource"
    ])
    error_message = "Unexpected actions"
  }
  assert {
    condition = data.aws_iam_policy_document.ecs_deploy_access_for_codebase_pipeline.statement[1].resources == toset([
      "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/my-app-staging",
      "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:service/my-app-staging/*"
    ])
    error_message = "Unexpected resources"
  }
  assert {
    condition     = data.aws_iam_policy_document.ecs_deploy_access_for_codebase_pipeline.statement[2].effect == "Allow"
    error_message = "Should be: Allow"
  }
  assert {
    condition = data.aws_iam_policy_document.ecs_deploy_access_for_codebase_pipeline.statement[2].actions == toset([
      "ecs:UpdateService",
      "ecs:DescribeServices",
      "ecs:TagResource"
    ])
    error_message = "Unexpected actions"
  }
  assert {
    condition = data.aws_iam_policy_document.ecs_deploy_access_for_codebase_pipeline.statement[2].resources == toset([
      "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/my-app-prod",
      "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:service/my-app-prod/*"
    ])
    error_message = "Unexpected resources"
  }
  assert {
    condition     = data.aws_iam_policy_document.ecs_deploy_access_for_codebase_pipeline.statement[3].effect == "Allow"
    error_message = "Should be: Allow"
  }
  assert {
    condition = data.aws_iam_policy_document.ecs_deploy_access_for_codebase_pipeline.statement[3].actions == toset([
      "ecs:DescribeTasks",
      "ecs:TagResource"
    ])
    error_message = "Unexpected actions"
  }
  assert {
    condition = data.aws_iam_policy_document.ecs_deploy_access_for_codebase_pipeline.statement[3].resources == toset([
      "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/my-app-dev",
      "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:task/my-app-dev/*"
    ])
    error_message = "Unexpected resources"
  }
  assert {
    condition     = data.aws_iam_policy_document.ecs_deploy_access_for_codebase_pipeline.statement[4].effect == "Allow"
    error_message = "Should be: Allow"
  }
  assert {
    condition = data.aws_iam_policy_document.ecs_deploy_access_for_codebase_pipeline.statement[4].actions == toset([
      "ecs:DescribeTasks",
      "ecs:TagResource"
    ])
    error_message = "Unexpected actions"
  }
  assert {
    condition = data.aws_iam_policy_document.ecs_deploy_access_for_codebase_pipeline.statement[4].resources == toset([
      "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/my-app-staging",
      "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:task/my-app-staging/*"
    ])
    error_message = "Unexpected resources"
  }
  assert {
    condition     = data.aws_iam_policy_document.ecs_deploy_access_for_codebase_pipeline.statement[5].effect == "Allow"
    error_message = "Should be: Allow"
  }
  assert {
    condition = data.aws_iam_policy_document.ecs_deploy_access_for_codebase_pipeline.statement[5].actions == toset([
      "ecs:DescribeTasks",
      "ecs:TagResource"
    ])
    error_message = "Unexpected actions"
  }
  assert {
    condition = data.aws_iam_policy_document.ecs_deploy_access_for_codebase_pipeline.statement[5].resources == toset([
      "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/my-app-prod",
      "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:task/my-app-prod/*"
    ])
    error_message = "Unexpected resources"
  }
  assert {
    condition     = data.aws_iam_policy_document.ecs_deploy_access_for_codebase_pipeline.statement[6].effect == "Allow"
    error_message = "Should be: Allow"
  }
  assert {
    condition = data.aws_iam_policy_document.ecs_deploy_access_for_codebase_pipeline.statement[6].actions == toset([
      "ecs:RunTask",
      "ecs:TagResource"
    ])
    error_message = "Unexpected actions"
  }
  assert {
    condition     = one(data.aws_iam_policy_document.ecs_deploy_access_for_codebase_pipeline.statement[6].resources) == "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:task-definition/my-app-dev-*:*"
    error_message = "Unexpected resources"
  }
  assert {
    condition     = data.aws_iam_policy_document.ecs_deploy_access_for_codebase_pipeline.statement[7].effect == "Allow"
    error_message = "Should be: Allow"
  }
  assert {
    condition = data.aws_iam_policy_document.ecs_deploy_access_for_codebase_pipeline.statement[7].actions == toset([
      "ecs:RunTask",
      "ecs:TagResource"
    ])
    error_message = "Unexpected actions"
  }
  assert {
    condition     = one(data.aws_iam_policy_document.ecs_deploy_access_for_codebase_pipeline.statement[7].resources) == "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:task-definition/my-app-staging-*:*"
    error_message = "Unexpected resources"
  }
  assert {
    condition     = data.aws_iam_policy_document.ecs_deploy_access_for_codebase_pipeline.statement[8].effect == "Allow"
    error_message = "Should be: Allow"
  }
  assert {
    condition = data.aws_iam_policy_document.ecs_deploy_access_for_codebase_pipeline.statement[8].actions == toset([
      "ecs:RunTask",
      "ecs:TagResource"
    ])
    error_message = "Unexpected actions"
  }
  assert {
    condition     = one(data.aws_iam_policy_document.ecs_deploy_access_for_codebase_pipeline.statement[8].resources) == "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:task-definition/my-app-prod-*:*"
    error_message = "Unexpected resources"
  }
  assert {
    condition     = data.aws_iam_policy_document.ecs_deploy_access_for_codebase_pipeline.statement[9].effect == "Allow"
    error_message = "Should be: Allow"
  }
  assert {
    condition     = one(data.aws_iam_policy_document.ecs_deploy_access_for_codebase_pipeline.statement[9].actions) == "ecs:ListTasks"
    error_message = "Unexpected actions"
  }
  assert {
    condition     = one(data.aws_iam_policy_document.ecs_deploy_access_for_codebase_pipeline.statement[9].resources) == "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:container-instance/my-app-dev/*"
    error_message = "Unexpected resources"
  }
  assert {
    condition     = data.aws_iam_policy_document.ecs_deploy_access_for_codebase_pipeline.statement[10].effect == "Allow"
    error_message = "Should be: Allow"
  }
  assert {
    condition     = one(data.aws_iam_policy_document.ecs_deploy_access_for_codebase_pipeline.statement[10].actions) == "ecs:ListTasks"
    error_message = "Unexpected actions"
  }
  assert {
    condition     = one(data.aws_iam_policy_document.ecs_deploy_access_for_codebase_pipeline.statement[10].resources) == "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:container-instance/my-app-staging/*"
    error_message = "Unexpected resources"
  }
  assert {
    condition     = data.aws_iam_policy_document.ecs_deploy_access_for_codebase_pipeline.statement[11].effect == "Allow"
    error_message = "Should be: Allow"
  }
  assert {
    condition     = one(data.aws_iam_policy_document.ecs_deploy_access_for_codebase_pipeline.statement[11].actions) == "ecs:ListTasks"
    error_message = "Unexpected actions"
  }
  assert {
    condition     = one(data.aws_iam_policy_document.ecs_deploy_access_for_codebase_pipeline.statement[11].resources) == "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:container-instance/my-app-prod/*"
    error_message = "Unexpected resources"
  }
  assert {
    condition     = data.aws_iam_policy_document.ecs_deploy_access_for_codebase_pipeline.statement[12].effect == "Allow"
    error_message = "Should be: Allow"
  }
  assert {
    condition = data.aws_iam_policy_document.ecs_deploy_access_for_codebase_pipeline.statement[12].actions == toset([
      "ecs:DescribeTaskDefinition",
      "ecs:RegisterTaskDefinition"
    ])
    error_message = "Unexpected actions"
  }
  assert {
    condition     = one(data.aws_iam_policy_document.ecs_deploy_access_for_codebase_pipeline.statement[12].resources) == "*"
    error_message = "Unexpected resources"
  }

  assert {
    condition     = data.aws_iam_policy_document.ecs_deploy_access_for_codebase_pipeline.statement[13].effect == "Allow"
    error_message = "Should be: Allow"
  }
  assert {
    condition     = one(data.aws_iam_policy_document.ecs_deploy_access_for_codebase_pipeline.statement[13].actions) == "iam:PassRole"
    error_message = "Unexpected actions"
  }
  assert {
    condition     = one(data.aws_iam_policy_document.ecs_deploy_access_for_codebase_pipeline.statement[13].resources) == "*"
    error_message = "Unexpected resources"
  }
  assert {
    condition     = [for el in data.aws_iam_policy_document.ecs_deploy_access_for_codebase_pipeline.statement[13].condition : el.test][0] == "StringLike"
    error_message = "Should be: aws:SecureTransport"
  }
  assert {
    condition     = [for el in data.aws_iam_policy_document.ecs_deploy_access_for_codebase_pipeline.statement[13].condition : one(el.values)][0] == "ecs-tasks.amazonaws.com"
    error_message = "Should be: aws:SecureTransport"
  }
  assert {
    condition     = [for el in data.aws_iam_policy_document.ecs_deploy_access_for_codebase_pipeline.statement[13].condition : el.variable][0] == "iam:PassedToService"
    error_message = "Should be: aws:SecureTransport"
  }
}

run "test_codebuild_manifests" {
  command = plan

  assert {
    condition     = aws_codebuild_project.codebase_deploy_manifests[0].name == "my-app-my-codebase-main-codebase-deploy-manifests"
    error_message = "Should be: 'my-app-my-codebase-main-codebase-deploy-manifests'"
  }
  assert {
    condition     = aws_codebuild_project.codebase_deploy_manifests[0].description == "Create image deploy manifests to deploy services"
    error_message = "Should be: 'Create image deploy manifests to deploy services'"
  }
  assert {
    condition     = aws_codebuild_project.codebase_deploy_manifests[0].build_timeout == 5
    error_message = "Should be: 5"
  }
  assert {
    condition     = one(aws_codebuild_project.codebase_deploy_manifests[0].artifacts).type == "CODEPIPELINE"
    error_message = "Should be: 'CODEPIPELINE'"
  }
  assert {
    condition     = one(aws_codebuild_project.codebase_deploy_manifests[0].cache).type == "S3"
    error_message = "Should be: 'S3'"
  }
  assert {
    condition     = one(aws_codebuild_project.codebase_deploy_manifests[0].cache).location == "my-app-my-codebase-codebase-pipeline-artifact-store"
    error_message = "Should be: 'my-app-my-codebase-codebase-pipeline-artifact-store'"
  }
  assert {
    condition     = one(aws_codebuild_project.codebase_deploy_manifests[0].environment).compute_type == "BUILD_GENERAL1_SMALL"
    error_message = "Should be: 'BUILD_GENERAL1_SMALL'"
  }
  assert {
    condition     = one(aws_codebuild_project.codebase_deploy_manifests[0].environment).image == "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    error_message = "Should be: 'aws/codebuild/amazonlinux2-x86_64-standard:5.0'"
  }
  assert {
    condition     = one(aws_codebuild_project.codebase_deploy_manifests[0].environment).type == "LINUX_CONTAINER"
    error_message = "Should be: 'LINUX_CONTAINER'"
  }
  assert {
    condition     = one(aws_codebuild_project.codebase_deploy_manifests[0].environment).image_pull_credentials_type == "CODEBUILD"
    error_message = "Should be: 'CODEBUILD'"
  }
  assert {
    condition = aws_codebuild_project.codebase_deploy_manifests[0].logs_config[0].cloudwatch_logs[
      0
    ].group_name == "codebuild/my-app-my-codebase-codebase-deploy-manifests/log-group"
    error_message = "Should be: 'codebuild/my-app-my-codebase-codebase-deploy-manifests/log-group'"
  }
  assert {
    condition = aws_codebuild_project.codebase_deploy_manifests[0].logs_config[0].cloudwatch_logs[
      0
    ].stream_name == "codebuild/my-app-my-codebase-codebase-deploy-manifests/log-stream"
    error_message = "Should be: 'codebuild/my-app-my-codebase-codebase-deploy-manifests/log-stream'"
  }
  assert {
    condition     = one(aws_codebuild_project.codebase_deploy_manifests[0].source).type == "CODEPIPELINE"
    error_message = "Should be: 'CODEPIPELINE'"
  }
  assert {
    condition     = length(regexall(".*\"exported-variables\":\\[\"CLUSTER_NAME_DEV\".*", aws_codebuild_project.codebase_deploy_manifests[0].source[0].buildspec)) > 0
    error_message = "Should contain: '\"exported-variables\":[\"CLUSTER_NAME_DEV\"'"
  }
  assert {
    condition     = jsonencode(aws_codebuild_project.codebase_deploy_manifests[0].tags) == jsonencode(var.expected_tags)
    error_message = "Should be: ${jsonencode(var.expected_tags)}"
  }
  assert {
    condition     = aws_kms_key.codebuild_kms_key.description == "KMS Key for my-app my-codebase CodeBuild encryption"
    error_message = "Should be: KMS Key for my-app my-codebase CodeBuild encryption"
  }

  assert {
    condition     = aws_kms_key.codebuild_kms_key.enable_key_rotation == true
    error_message = "Should be: true"
  }

  assert {
    condition     = jsonencode(aws_kms_key.codebuild_kms_key.tags) == jsonencode(var.expected_tags)
    error_message = "Should be: ${jsonencode(var.expected_tags)}"
  }

  # Cloudwatch config:
  assert {
    condition     = aws_cloudwatch_log_group.codebase_deploy_manifests.name == "codebuild/my-app-my-codebase-codebase-deploy-manifests/log-group"
    error_message = "Should be: 'codebuild/my-app-my-codebase-codebase-deploy-manifests/log-group'"
  }
  assert {
    condition     = aws_cloudwatch_log_group.codebase_deploy_manifests.retention_in_days == 90
    error_message = "Should be: 90"
  }
  assert {
    condition     = aws_cloudwatch_log_stream.codebase_deploy_manifests.name == "codebuild/my-app-my-codebase-codebase-deploy-manifests/log-stream"
    error_message = "Should be: 'codebuild/my-app-my-codebase-codebase-deploy-manifests/log-stream'"
  }
  assert {
    condition     = aws_cloudwatch_log_stream.codebase_deploy_manifests.log_group_name == "codebuild/my-app-my-codebase-codebase-deploy-manifests/log-group"
    error_message = "Should be: 'codebuild/my-app-my-codebase-codebase-deploy-manifests/log-group'"
  }
}

run "test_main_pipeline" {
  command = plan

  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].name == "my-app-my-codebase-main-codebase-pipeline"
    error_message = "Should be: 'my-app-my-codebase-main-codebase-pipeline'"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].variable[0].name == "IMAGE_TAG"
    error_message = "Should be: 'IMAGE_TAG'"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].variable[0].default_value == "branch-main"
    error_message = "Should be: 'branch-main'"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].variable[0].description == "Tagged image in ECR to deploy"
    error_message = "Should be: 'Tagged image in ECR to deploy'"
  }
  assert {
    condition     = tolist(aws_codepipeline.codebase_pipeline[0].artifact_store)[0].location == "my-app-my-codebase-codebase-pipeline-artifact-store"
    error_message = "Should be: 'my-app-my-codebase-codebase-pipeline-artifact-store'"
  }
  assert {
    condition     = tolist(aws_codepipeline.codebase_pipeline[0].artifact_store)[0].type == "S3"
    error_message = "Should be: 'S3'"
  }
  assert {
    condition     = tolist(aws_codepipeline.codebase_pipeline[0].artifact_store)[0].encryption_key[0].type == "KMS"
    error_message = "Should be: 'KMS'"
  }
  assert {
    condition     = jsonencode(aws_codepipeline.codebase_pipeline[0].tags) == jsonencode(var.expected_tags)
    error_message = "Should be: ${jsonencode(var.expected_tags)}"
  }
  assert {
    condition     = length(aws_codepipeline.codebase_pipeline[0].stage) == 3
    error_message = "Should be: 3"
  }

  # Source stage
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[0].name == "Source"
    error_message = "Should be: Source"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[0].action[0].name == "Source"
    error_message = "Should be: Source"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[0].action[0].category == "Source"
    error_message = "Should be: Source"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[0].action[0].owner == "AWS"
    error_message = "Should be: AWS"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[0].action[0].provider == "ECR"
    error_message = "Should be: ECR"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[0].action[0].version == "1"
    error_message = "Should be: 1"
  }
  assert {
    condition     = one(aws_codepipeline.codebase_pipeline[0].stage[0].action[0].output_artifacts) == "source_output"
    error_message = "Should be: source_output"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[0].action[0].namespace == "source_ecr"
    error_message = "Should be: source_ecr"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[0].action[0].configuration.RepositoryName == "my-app/my-codebase"
    error_message = "Should be: my-app/my-codebase"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[0].action[0].configuration.ImageTag == "branch-main"
    error_message = "Should be: branch-main"
  }

  # Create-Deploy-Manifests stage
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[1].name == "Create-Deploy-Manifests"
    error_message = "Should be: Create-Deploy-Manifests"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[1].action[0].name == "CreateManifests"
    error_message = "Should be: CreateManifests"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[1].action[0].category == "Build"
    error_message = "Should be: Build"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[1].action[0].owner == "AWS"
    error_message = "Should be: AWS"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[1].action[0].provider == "CodeBuild"
    error_message = "Should be: CodeBuild"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[1].action[0].version == "1"
    error_message = "Should be: 1"
  }
  assert {
    condition     = one(aws_codepipeline.codebase_pipeline[0].stage[1].action[0].input_artifacts) == "source_output"
    error_message = "Should be: source_output"
  }
  assert {
    condition     = one(aws_codepipeline.codebase_pipeline[0].stage[1].action[0].output_artifacts) == "manifest_output"
    error_message = "Should be: manifest_output"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[1].action[0].configuration.ProjectName == "my-app-my-codebase-main-codebase-deploy-manifests"
    error_message = "Should be: my-app-my-codebase-main-codebase-deploy-manifests"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[1].action[0].configuration.EnvironmentVariables == "[{\"name\":\"APPLICATION\",\"value\":\"my-app\"},{\"name\":\"ENVIRONMENTS\",\"value\":\"[\\\"dev\\\"]\"},{\"name\":\"SERVICES\",\"value\":\"[\\\"service-1\\\",\\\"service-2\\\"]\"},{\"name\":\"REPOSITORY_URL\",\"value\":\"${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/my-app/my-codebase\"},{\"name\":\"IMAGE_TAG\",\"value\":\"#{variables.IMAGE_TAG}\"}]"
    error_message = "Configuration environment variables incorrect"
  }

  # Deploy dev environment stage
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].name == "Deploy-dev"
    error_message = "Should be: Deploy-dev"
  }

  # Deploy service-1 action
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].action[0].name == "service-1"
    error_message = "Action name incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].action[0].category == "Deploy"
    error_message = "Action category incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].action[0].owner == "AWS"
    error_message = "Action owner incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].action[0].provider == "ECS"
    error_message = "Action provider incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].action[0].version == "1"
    error_message = "Action Version incorrect"
  }
  assert {
    condition     = length(aws_codepipeline.codebase_pipeline[0].stage[2].action[0].input_artifacts) == 1
    error_message = "Input artifacts incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].action[0].input_artifacts[0] == "manifest_output"
    error_message = "Input artifacts incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].action[0].run_order == 2
    error_message = "Run order incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].action[0].role_arn == "arn:aws:iam::000123456789:role/my-app-dev-codebase-pipeline-deploy-role"
    error_message = "Role ARN incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].action[0].configuration.ClusterName == "#{build_manifest.CLUSTER_NAME_DEV}"
    error_message = "Configuration ClusterName incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].action[0].configuration.ServiceName == "#{build_manifest.SERVICE_NAME_DEV_SERVICE_1}"
    error_message = "Configuration ServiceName incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].action[0].configuration.FileName == "image-definitions-service-1.json"
    error_message = "Configuration FileName incorrect"
  }

  # Deploy service-2 action
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].action[1].name == "service-2"
    error_message = "Action name incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].action[1].run_order == 3
    error_message = "Run order incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].action[1].role_arn == "arn:aws:iam::000123456789:role/my-app-dev-codebase-pipeline-deploy-role"
    error_message = "Role ARN incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].action[1].configuration.ClusterName == "#{build_manifest.CLUSTER_NAME_DEV}"
    error_message = "Configuration ClusterName incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].action[1].configuration.ServiceName == "#{build_manifest.SERVICE_NAME_DEV_SERVICE_2}"
    error_message = "Configuration ServiceName incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].action[1].configuration.FileName == "image-definitions-service-2.json"
    error_message = "Configuration FileName incorrect"
  }
}

run "test_tagged_pipeline" {
  command = plan

  assert {
    condition     = aws_codepipeline.codebase_pipeline[1].name == "my-app-my-codebase-tagged-codebase-pipeline"
    error_message = "Should be: 'my-app-my-codebase-tagged-codebase-pipeline'"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[1].variable[0].default_value == "tag-latest"
    error_message = "Should be: 'tag-latest'"
  }
  assert {
    condition     = length(aws_codepipeline.codebase_pipeline[1].stage) == 4
    error_message = "Should be: 4"
  }

  # Source stage
  assert {
    condition     = aws_codepipeline.codebase_pipeline[1].stage[0].action[0].configuration.ImageTag == "tag-latest"
    error_message = "Should be: tag-latest"
  }

  # Create-Deploy-Manifests stage
  assert {
    condition     = aws_codepipeline.codebase_pipeline[1].stage[1].name == "Create-Deploy-Manifests"
    error_message = "Should be: Create-Deploy-Manifests"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[1].stage[1].action[0].configuration.ProjectName == "my-app-my-codebase-tagged-codebase-deploy-manifests"
    error_message = "Should be: my-app-my-codebase-tagged-codebase-deploy-manifests"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[1].stage[1].action[0].configuration.EnvironmentVariables == "[{\"name\":\"APPLICATION\",\"value\":\"my-app\"},{\"name\":\"ENVIRONMENTS\",\"value\":\"[\\\"staging\\\",\\\"prod\\\"]\"},{\"name\":\"SERVICES\",\"value\":\"[\\\"service-1\\\",\\\"service-2\\\"]\"},{\"name\":\"REPOSITORY_URL\",\"value\":\"${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/my-app/my-codebase\"},{\"name\":\"IMAGE_TAG\",\"value\":\"#{variables.IMAGE_TAG}\"}]"
    error_message = "Configuration environment variables incorrect"
  }

  # Deploy staging environment stage
  assert {
    condition     = aws_codepipeline.codebase_pipeline[1].stage[2].name == "Deploy-staging"
    error_message = "Should be: Deploy-staging"
  }

  # Deploy service-1 action
  assert {
    condition     = aws_codepipeline.codebase_pipeline[1].stage[2].action[0].name == "service-1"
    error_message = "Action name incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[1].stage[2].action[0].run_order == 2
    error_message = "Run order incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[1].stage[2].action[0].role_arn == "arn:aws:iam::000123456789:role/my-app-staging-codebase-pipeline-deploy-role"
    error_message = "Role ARN incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[1].stage[2].action[0].configuration.ClusterName == "#{build_manifest.CLUSTER_NAME_STAGING}"
    error_message = "Configuration ClusterName incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[1].stage[2].action[0].configuration.ServiceName == "#{build_manifest.SERVICE_NAME_STAGING_SERVICE_1}"
    error_message = "Configuration ServiceName incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[1].stage[2].action[0].configuration.FileName == "image-definitions-service-1.json"
    error_message = "Configuration FileName incorrect"
  }

  # Deploy service-2 action
  assert {
    condition     = aws_codepipeline.codebase_pipeline[1].stage[2].action[1].name == "service-2"
    error_message = "Action name incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[1].stage[2].action[1].run_order == 3
    error_message = "Run order incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[1].stage[2].action[1].role_arn == "arn:aws:iam::000123456789:role/my-app-staging-codebase-pipeline-deploy-role"
    error_message = "Role ARN incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[1].stage[2].action[1].configuration.ClusterName == "#{build_manifest.CLUSTER_NAME_STAGING}"
    error_message = "Configuration ClusterName incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[1].stage[2].action[1].configuration.ServiceName == "#{build_manifest.SERVICE_NAME_STAGING_SERVICE_2}"
    error_message = "Configuration ServiceName incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[1].stage[2].action[1].configuration.FileName == "image-definitions-service-2.json"
    error_message = "Configuration FileName incorrect"
  }

  # Deploy prod environment stage
  assert {
    condition     = aws_codepipeline.codebase_pipeline[1].stage[3].name == "Deploy-prod"
    error_message = "Should be: Deploy-prod"
  }

  # Approval action
  assert {
    condition     = aws_codepipeline.codebase_pipeline[1].stage[3].action[0].name == "Approve-prod"
    error_message = "Action name incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[1].stage[3].action[0].category == "Approval"
    error_message = "Action category incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[1].stage[3].action[0].owner == "AWS"
    error_message = "Action owner incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[1].stage[3].action[0].provider == "Manual"
    error_message = "Action provider incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[1].stage[3].action[0].version == "1"
    error_message = "Action Version incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[1].stage[3].action[0].run_order == 1
    error_message = "Run order incorrect"
  }

  # Deploy service-1 action
  assert {
    condition     = aws_codepipeline.codebase_pipeline[1].stage[3].action[1].name == "service-1"
    error_message = "Action name incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[1].stage[3].action[1].run_order == 2
    error_message = "Run order incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[1].stage[3].action[1].role_arn == "arn:aws:iam::123456789000:role/my-app-prod-codebase-pipeline-deploy-role"
    error_message = "Role ARN incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[1].stage[3].action[1].configuration.ClusterName == "#{build_manifest.CLUSTER_NAME_PROD}"
    error_message = "Configuration ClusterName incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[1].stage[3].action[1].configuration.ServiceName == "#{build_manifest.SERVICE_NAME_PROD_SERVICE_1}"
    error_message = "Configuration ServiceName incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[1].stage[3].action[1].configuration.FileName == "image-definitions-service-1.json"
    error_message = "Configuration FileName incorrect"
  }

  # Deploy service-2 action
  assert {
    condition     = aws_codepipeline.codebase_pipeline[1].stage[3].action[2].name == "service-2"
    error_message = "Action name incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[1].stage[3].action[2].run_order == 3
    error_message = "Run order incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[1].stage[3].action[2].role_arn == "arn:aws:iam::123456789000:role/my-app-prod-codebase-pipeline-deploy-role"
    error_message = "Role ARN incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[1].stage[3].action[2].configuration.ClusterName == "#{build_manifest.CLUSTER_NAME_PROD}"
    error_message = "Configuration ClusterName incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[1].stage[3].action[2].configuration.ServiceName == "#{build_manifest.SERVICE_NAME_PROD_SERVICE_2}"
    error_message = "Configuration ServiceName incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[1].stage[3].action[2].configuration.FileName == "image-definitions-service-2.json"
    error_message = "Configuration FileName incorrect"
  }
}

run "test_event_bridge" {
  command = plan

  # Main pipeline trigger
  assert {
    condition     = aws_cloudwatch_event_rule.ecr_image_publish[0].name == "my-app-my-codebase-ecr-image-publish-main"
    error_message = "Should be: 'my-app-my-codebase-ecr-image-publish-main'"
  }
  assert {
    condition     = aws_cloudwatch_event_rule.ecr_image_publish[0].description == "Trigger main deploy pipeline when an ECR image is published"
    error_message = "Should be: 'Trigger main deploy pipeline when an ECR image is published'"
  }
  assert {
    condition     = aws_cloudwatch_event_rule.ecr_image_publish[0].event_pattern == "{\"detail\":{\"action-type\":[\"PUSH\"],\"image-tag\":[\"branch-main\"],\"repository-name\":[\"my-app/my-codebase\"],\"result\":[\"SUCCESS\"]},\"detail-type\":[\"ECR Image Action\"],\"source\":[\"aws.ecr\"]}"
    error_message = "Event pattern is incorrect"
  }
  assert {
    condition     = aws_cloudwatch_event_target.codepipeline[0].rule == "my-app-my-codebase-ecr-image-publish-main"
    error_message = "Should be: 'my-app-my-codebase-ecr-image-publish-main'"
  }

  # Tagged pipeline trigger
  assert {
    condition     = aws_cloudwatch_event_rule.ecr_image_publish[1].name == "my-app-my-codebase-ecr-image-publish-tagged"
    error_message = "Should be: 'my-app-my-codebase-ecr-image-publish-tagged'"
  }
  assert {
    condition     = aws_cloudwatch_event_rule.ecr_image_publish[1].description == "Trigger tagged deploy pipeline when an ECR image is published"
    error_message = "Should be: 'Trigger tagged deploy pipeline when an ECR image is published'"
  }
  assert {
    condition     = aws_cloudwatch_event_rule.ecr_image_publish[1].event_pattern == "{\"detail\":{\"action-type\":[\"PUSH\"],\"image-tag\":[\"tag-latest\"],\"repository-name\":[\"my-app/my-codebase\"],\"result\":[\"SUCCESS\"]},\"detail-type\":[\"ECR Image Action\"],\"source\":[\"aws.ecr\"]}"
    error_message = "Event pattern is incorrect"
  }
  assert {
    condition     = aws_cloudwatch_event_target.codepipeline[1].rule == "my-app-my-codebase-ecr-image-publish-tagged"
    error_message = "Should be: 'my-app-my-codebase-ecr-image-publish-tagged'"
  }

  # IAM roles
  assert {
    condition     = aws_iam_role.event_bridge_pipeline_trigger.name == "my-app-my-codebase-event-bridge-pipeline-trigger"
    error_message = "Should be: 'my-app-my-codebase-event-bridge-pipeline-trigger'"
  }
  assert {
    condition     = aws_iam_role.event_bridge_pipeline_trigger.assume_role_policy == "{\"Sid\": \"AssumeEventBridge\"}"
    error_message = "Should be: {\"Sid\": \"AssumeEventBridge\"}"
  }
  assert {
    condition     = jsonencode(aws_iam_role.event_bridge_pipeline_trigger.tags) == jsonencode(var.expected_tags)
    error_message = "Should be: ${jsonencode(var.expected_tags)}"
  }
  assert {
    condition     = aws_iam_role_policy.event_bridge_pipeline_trigger.name == "my-app-my-codebase-pipeline-trigger-access-for-event-bridge"
    error_message = "Should be: 'my-app-my-codebase-pipeline-trigger-access-for-event-bridge'"
  }
  assert {
    condition     = aws_iam_role_policy.event_bridge_pipeline_trigger.role == "my-app-my-codebase-event-bridge-pipeline-trigger"
    error_message = "Should be: 'my-app-my-codebase-event-bridge-pipeline-trigger'"
  }
  assert {
    condition     = aws_iam_role_policy.event_bridge_pipeline_trigger.policy == "{\"Sid\": \"EventBridgePipelineTrigger\"}"
    error_message = "Unexpected policy"
  }

  # IAM Policy documents
  assert {
    condition     = data.aws_iam_policy_document.event_bridge_pipeline_trigger.statement[0].effect == "Allow"
    error_message = "Should be: Allow"
  }
  assert {
    condition     = one(data.aws_iam_policy_document.event_bridge_pipeline_trigger.statement[0].actions) == "codepipeline:StartPipelineExecution"
    error_message = "Should be: codepipeline:StartPipelineExecution"
  }
  assert {
    condition     = one(data.aws_iam_policy_document.event_bridge_pipeline_trigger.statement[0].resources) == "arn:aws:codepipeline:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:my-app-my-codebase-main-codebase-pipeline"
    error_message = "Unexpected resources"
  }
  assert {
    condition     = data.aws_iam_policy_document.assume_event_bridge_policy.statement[0].effect == "Allow"
    error_message = "Should be: Allow"
  }
  assert {
    condition     = one(data.aws_iam_policy_document.assume_event_bridge_policy.statement[0].actions) == "sts:AssumeRole"
    error_message = "Should be: sts:AssumeRole"
  }
  assert {
    condition     = one(data.aws_iam_policy_document.assume_event_bridge_policy.statement[0].principals).type == "Service"
    error_message = "Should be: Service"
  }
  assert {
    condition     = contains(one(data.aws_iam_policy_document.assume_event_bridge_policy.statement[0].principals).identifiers, "events.amazonaws.com")
    error_message = "Should contain: events.amazonaws.com"
  }
}

run "test_pipeline_single_run_group" {
  command = plan

  variables {
    services = [
      {
        "run_group_1" : [
          "service-1",
          "service-2",
          "service-3",
          "service-4"
        ]
      }
    ]
  }

  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[1].action[0].configuration.EnvironmentVariables == "[{\"name\":\"APPLICATION\",\"value\":\"my-app\"},{\"name\":\"ENVIRONMENTS\",\"value\":\"[\\\"dev\\\"]\"},{\"name\":\"SERVICES\",\"value\":\"[\\\"service-1\\\",\\\"service-2\\\",\\\"service-3\\\",\\\"service-4\\\"]\"},{\"name\":\"REPOSITORY_URL\",\"value\":\"${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/my-app/my-codebase\"},{\"name\":\"IMAGE_TAG\",\"value\":\"#{variables.IMAGE_TAG}\"}]"
    error_message = "Configuration environment variables incorrect"
  }

  # service-1
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].action[0].name == "service-1"
    error_message = "Action name incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].action[0].run_order == 2
    error_message = "Run order incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].action[0].role_arn == "arn:aws:iam::000123456789:role/my-app-dev-codebase-pipeline-deploy-role"
    error_message = "Role ARN incorrect"
  }

  # service-2
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].action[1].name == "service-2"
    error_message = "Action name incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].action[1].run_order == 2
    error_message = "Run order incorrect"
  }

  # service-3
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].action[2].name == "service-3"
    error_message = "Action name incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].action[2].run_order == 2
    error_message = "Run order incorrect"
  }

  # service-4
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].action[3].name == "service-4"
    error_message = "Action name incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].action[3].run_order == 2
    error_message = "Run order incorrect"
  }
}

run "test_pipeline_multiple_run_groups" {
  command = plan

  variables {
    services = [
      {
        "run_group_1" : [
          "service-1"
        ]
      },
      {
        "run_group_2" : [
          "service-2",
          "service-3"
        ]
      },
      {
        "run_group_3" : [
          "service-4"
        ]
      },
      {
        "run_group_4" : [
          "service-5",
          "service-6",
          "service-7"
        ]
      }
    ]
  }

  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[1].action[0].configuration.EnvironmentVariables == "[{\"name\":\"APPLICATION\",\"value\":\"my-app\"},{\"name\":\"ENVIRONMENTS\",\"value\":\"[\\\"dev\\\"]\"},{\"name\":\"SERVICES\",\"value\":\"[\\\"service-1\\\",\\\"service-2\\\",\\\"service-3\\\",\\\"service-4\\\",\\\"service-5\\\",\\\"service-6\\\",\\\"service-7\\\"]\"},{\"name\":\"REPOSITORY_URL\",\"value\":\"${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/my-app/my-codebase\"},{\"name\":\"IMAGE_TAG\",\"value\":\"#{variables.IMAGE_TAG}\"}]"
    error_message = "Configuration environment variables incorrect"
  }

  # service-1
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].action[0].name == "service-1"
    error_message = "Action name incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].action[0].run_order == 2
    error_message = "Run order incorrect"
  }

  # service-2
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].action[1].name == "service-2"
    error_message = "Action name incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].action[1].run_order == 3
    error_message = "Run order incorrect"
  }

  # service-3
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].action[2].name == "service-3"
    error_message = "Action name incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].action[2].run_order == 3
    error_message = "Run order incorrect"
  }

  # service-4
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].action[3].name == "service-4"
    error_message = "Action name incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].action[3].run_order == 4
    error_message = "Run order incorrect"
  }

  # service-5
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].action[4].name == "service-5"
    error_message = "Action name incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].action[4].run_order == 5
    error_message = "Run order incorrect"
  }

  # service-6
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].action[5].name == "service-6"
    error_message = "Action name incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].action[5].run_order == 5
    error_message = "Run order incorrect"
  }

  # service-7
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].action[6].name == "service-7"
    error_message = "Action name incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].action[6].run_order == 5
    error_message = "Run order incorrect"
  }
}

run "test_pipeline_multiple_run_groups_multiple_environment_approval" {
  command = plan

  variables {
    services = [
      {
        "run_group_1" : [
          "service-1"
        ]
      },
      {
        "run_group_2" : [
          "service-2",
          "service-3"
        ]
      },
      {
        "run_group_3" : [
          "service-4"
        ]
      }
    ]
    pipelines = [
      {
        name   = "main",
        branch = "main",
        environments = [
          { name = "dev" },
          { name = "prod", requires_approval = true }
        ]
      }
    ]
  }

  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[1].action[0].configuration.EnvironmentVariables == "[{\"name\":\"APPLICATION\",\"value\":\"my-app\"},{\"name\":\"ENVIRONMENTS\",\"value\":\"[\\\"dev\\\",\\\"prod\\\"]\"},{\"name\":\"SERVICES\",\"value\":\"[\\\"service-1\\\",\\\"service-2\\\",\\\"service-3\\\",\\\"service-4\\\"]\"},{\"name\":\"REPOSITORY_URL\",\"value\":\"${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/my-app/my-codebase\"},{\"name\":\"IMAGE_TAG\",\"value\":\"#{variables.IMAGE_TAG}\"}]"
    error_message = "Configuration environment variables incorrect"
  }

  # Dev
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].name == "Deploy-dev"
    error_message = "Should be: Deploy-dev"
  }

  # service-1
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].action[0].name == "service-1"
    error_message = "Action name incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].action[0].run_order == 2
    error_message = "Run order incorrect"
  }

  # service-2
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].action[1].name == "service-2"
    error_message = "Action name incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].action[1].run_order == 3
    error_message = "Run order incorrect"
  }

  # service-3
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].action[2].name == "service-3"
    error_message = "Action name incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].action[2].run_order == 3
    error_message = "Run order incorrect"
  }

  # service-4
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].action[3].name == "service-4"
    error_message = "Action name incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[2].action[3].run_order == 4
    error_message = "Run order incorrect"
  }

  # Prod
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[3].name == "Deploy-prod"
    error_message = "Should be: Deploy-prod"
  }

  # Approval
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[3].action[0].name == "Approve-prod"
    error_message = "Action name incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[3].action[0].run_order == 1
    error_message = "Run order incorrect"
  }

  # service-1
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[3].action[1].name == "service-1"
    error_message = "Action name incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[3].action[1].run_order == 2
    error_message = "Run order incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[3].action[1].role_arn == "arn:aws:iam::123456789000:role/my-app-prod-codebase-pipeline-deploy-role"
    error_message = "Role ARN incorrect"
  }

  # service-2
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[3].action[2].name == "service-2"
    error_message = "Action name incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[3].action[2].run_order == 3
    error_message = "Run order incorrect"
  }

  # service-3
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[3].action[3].name == "service-3"
    error_message = "Action name incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[3].action[3].run_order == 3
    error_message = "Run order incorrect"
  }

  # service-4
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[3].action[4].name == "service-4"
    error_message = "Action name incorrect"
  }
  assert {
    condition     = aws_codepipeline.codebase_pipeline[0].stage[3].action[4].run_order == 4
    error_message = "Run order incorrect"
  }
}
