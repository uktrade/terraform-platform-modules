data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_iam_policy_document" "assume_codepipeline_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "access_artifact_store" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObjectAcl",
      "s3:PutObject",
    ]

    resources = [
      module.artifact_store.arn,
      "${module.artifact_store.arn}/*"
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["codestar-connections:UseConnection"]
    resources = [data.aws_codestarconnections_connection.github_codestar_connection.arn]
  }

  statement {
    effect = "Allow"

    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt"
    ]
    resources = [
      module.artifact_store.kms_key_arn
    ]
  }
}

data "aws_iam_policy_document" "assume_codebuild_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "write_environment_pipeline_codebuild_logs" {
  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      aws_cloudwatch_log_group.environment_pipeline_codebuild.arn,
      "${aws_cloudwatch_log_group.environment_pipeline_codebuild.arn}:*"
    ]
  }
}

data "aws_s3_bucket" "state_bucket" {
  bucket = "terraform-platform-state-${local.stages[0].accounts.deploy.name}"
}

data "aws_iam_policy_document" "state_bucket_access" {
  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [
      data.aws_s3_bucket.state_bucket.arn,
      "${data.aws_s3_bucket.state_bucket.arn}/*"
    ]
  }
}

data "aws_kms_key" "state_kms_key" {
  key_id = "alias/terraform-platform-state-s3-key-${local.stages[0].accounts.deploy.name}"
}

data "aws_iam_policy_document" "state_kms_key_access" {
  statement {
    actions = [
      "kms:ListKeys",
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [
      data.aws_kms_key.state_kms_key.arn
    ]
  }
}

data "aws_iam_policy_document" "state_dynamo_db_access" {
  statement {
    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    resources = [
      "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/terraform-platform-lockdb-${local.stages[0].accounts.deploy.name}"
    ]
  }
}

data "aws_iam_policy_document" "ec2_read_access" {
  statement {
    actions = [
      "ec2:DescribeVpcs",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeNetworkInterfaces"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "ec2:DescribeVpcAttribute",
      "ec2:CreateSecurityGroup"
    ]
    resources = [
      "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:vpc/*"
    ]
  }
}

data "aws_ssm_parameter" "central_log_group_parameter" {
  name = "/copilot/tools/central_log_groups"
}

data "aws_iam_policy_document" "ssm_read_access" {
  statement {
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters"
    ]
    resources = [
      data.aws_ssm_parameter.central_log_group_parameter.arn
    ]
  }
}

data "aws_iam_policy_document" "dns_account_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    resources = local.dns_account_assumed_roles
  }
}

data "aws_iam_policy_document" "load_balancer" {
  statement {
    actions = [
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetGroupAttributes",
      "elasticloadbalancing:DescribeTags",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DescribeSSLPolicies",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:DescribeRules"
    ]
    resources = [
      "*"
    ]
  }

  dynamic "statement" {
    for_each = var.environments
    content {
      actions = [
        "elasticloadbalancing:CreateTargetGroup",
        "elasticloadbalancing:AddTags",
        "elasticloadbalancing:ModifyTargetGroupAttributes",
        "elasticloadbalancing:DeleteTargetGroup"
      ]
      resources = [
        "arn:aws:elasticloadbalancing:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:targetgroup/${var.application}-${statement.value.name}-http/*"
      ]
    }
  }

  dynamic "statement" {
    for_each = var.environments
    content {
      actions = [
        "elasticloadbalancing:CreateLoadBalancer",
        "elasticloadbalancing:AddTags",
        "elasticloadbalancing:ModifyLoadBalancerAttributes",
        "elasticloadbalancing:DeleteLoadBalancer",
        "elasticloadbalancing:CreateListener"
      ]
      resources = [
        "arn:aws:elasticloadbalancing:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:loadbalancer/app/${var.application}-${statement.value.name}/*"
      ]
    }
  }

  dynamic "statement" {
    for_each = var.environments
    content {
      actions = [
        "elasticloadbalancing:AddTags"
      ]
      resources = [
        "arn:aws:elasticloadbalancing:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:listener/app/${var.application}-${statement.value.name}/*"
      ]
    }
  }
}

data "aws_iam_policy_document" "certificate" {
  statement {
    actions = [
      "acm:RequestCertificate",
      "acm:AddTagsToCertificate",
      "acm:DescribeCertificate",
      "acm:ListTagsForCertificate",
      "acm:DeleteCertificate"
    ]
    resources = [
      "arn:aws:acm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:certificate/*"
    ]
  }
}

data "aws_iam_policy_document" "security_group" {
  statement {
    actions = [
      "ec2:CreateSecurityGroup",
      "ec2:CreateTags",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:DeleteSecurityGroup",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:AuthorizeSecurityGroupEgress"
    ]
    resources = [
      "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:security-group/*"
    ]
  }
}

data "aws_iam_policy_document" "ssm_parameter" {
  statement {
    actions = [
      "ssm:DescribeParameters"
    ]
    resources = [
      "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
    ]
  }

  statement {
    actions = [
      "ssm:PutParameter",
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
      "ssm:DeleteParameter",
      "ssm:AddTagsToResource",
      "ssm:ListTagsForResource"
    ]
    resources = [
      "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/copilot/${var.application}/*/secrets/*",
      "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/copilot/applications/${var.application}",
      "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/copilot/applications/${var.application}/*"
    ]
  }
}

data "aws_iam_policy_document" "cloudwatch" {
  dynamic "statement" {
    for_each = var.environments
    content {
      actions = [
        "cloudwatch:GetDashboard",
        "cloudwatch:PutDashboard",
        "cloudwatch:DeleteDashboards"
      ]
      resources = [
        "arn:aws:cloudwatch::${data.aws_caller_identity.current.account_id}:dashboard/${var.application}-${statement.value.name}-compute"
      ]
    }
  }

  dynamic "statement" {
    for_each = var.environments
    content {
      actions = [
        "resource-groups:GetGroup",
        "resource-groups:CreateGroup",
        "resource-groups:Tag",
        "resource-groups:GetGroupQuery",
        "resource-groups:GetGroupConfiguration",
        "resource-groups:GetTags",
        "resource-groups:DeleteGroup"
      ]
      resources = [
        "arn:aws:resource-groups:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:group/${var.application}-${statement.value.name}-application-insights-resources"
      ]
    }
  }

  dynamic "statement" {
    for_each = var.environments
    content {
      actions = [
        "applicationinsights:CreateApplication",
        "applicationinsights:TagResource",
        "applicationinsights:DescribeApplication",
        "applicationinsights:ListTagsForResource",
        "applicationinsights:DeleteApplication"
      ]
      resources = [
        "arn:aws:applicationinsights:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:application/resource-group/${var.application}-${statement.value.name}-application-insights-resources"
      ]
    }
  }
}

data "aws_iam_policy_document" "logs" {
  statement {
    actions = [
      "logs:DescribeResourcePolicies",
      "logs:PutResourcePolicy",
      "logs:DeleteResourcePolicy",
      "logs:DescribeLogGroups"
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group::log-stream:"
    ]
  }

  statement {
    actions = [
      "logs:PutSubscriptionFilter"
    ]
    resources = [
      local.central_log_destination_arn
    ]
  }

  statement {
    actions = [
      "logs:PutRetentionPolicy",
      "logs:ListTagsLogGroup",
      "logs:DeleteLogGroup",
      "logs:CreateLogGroup",
      "logs:PutSubscriptionFilter",
      "logs:DescribeSubscriptionFilters",
      "logs:DeleteSubscriptionFilter",
      "logs:TagResource"
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/opensearch/*",
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/rds/*",
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/elasticache/*"
    ]
  }
}

data "aws_iam_policy_document" "kms_key" {
  statement {
    actions = [
      "kms:CreateKey",
      "kms:ListAliases"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "kms:*"
    ]
    resources = [
      "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/*"
    ]
  }

  dynamic "statement" {
    for_each = var.environments
    content {
      actions = [
        "kms:CreateAlias",
        "kms:DeleteAlias"
      ]
      resources = [
        "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:alias/${var.application}-${statement.value.name}-*-key"
      ]
    }
  }
}



data "aws_iam_policy_document" "redis" {
  statement {
    actions = [
      "elasticache:CreateCacheSubnetGroup",
      "elasticache:AddTagsToResource",
      "elasticache:DescribeCacheSubnetGroups",
      "elasticache:ListTagsForResource",
      "elasticache:DeleteCacheSubnetGroup",
      "elasticache:CreateReplicationGroup"
    ]
    resources = [
      "arn:aws:elasticache:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:subnetgroup:*"
    ]
  }

  statement {
    actions = [
      "elasticache:CreateReplicationGroup",
      "elasticache:AddTagsToResource",
      "elasticache:DescribeReplicationGroups",
      "elasticache:ListTagsForResource",
      "elasticache:DeleteReplicationGroup"
    ]
    resources = [
      "arn:aws:elasticache:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:replicationgroup:*",
      "arn:aws:elasticache:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parametergroup:*"
    ]
  }

  statement {
    actions = [
      "elasticache:DescribeCacheClusters"
    ]
    resources = [
      "arn:aws:elasticache:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster:*"
    ]
  }
}

data "aws_iam_policy_document" "postgres" {
  statement {
    actions = [
      "iam:PassRole"
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.application}-adminrole"
    ]
  }
  dynamic "statement" {
    for_each = var.environments
    content {
      actions = [
        "iam:CreateRole",
        "iam:GetRole",
        "iam:ListRolePolicies",
        "iam:ListAttachedRolePolicies",
        "iam:ListInstanceProfilesForRole",
        "iam:DeleteRole",
        "iam:AttachRolePolicy",
        "iam:PutRolePolicy",
        "iam:GetRolePolicy",
        "iam:PassRole"
      ]
      resources = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.application}-${statement.value.name}-*",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/rds-enhanced-monitoring-*"
      ]
    }
  }

  dynamic "statement" {
    for_each = var.environments
    content {
      actions = [
        "lambda:GetFunction",
        "lambda:ListVersionsByFunction",
        "lambda:GetFunctionCodeSigningConfig"
      ]
      resources = [
        "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:${var.application}-${statement.value.name}-*"
      ]
    }
  }

  dynamic "statement" {
    for_each = var.environments
    content {
      actions = [
        "rds:CreateDBParameterGroup",
        "rds:AddTagsToResource",
        "rds:ModifyDBParameterGroup",
        "rds:DescribeDBParameterGroups",
        "rds:DescribeDBParameters",
        "rds:ListTagsForResource",
        "rds:CreateDBInstance"
      ]
      resources = [
        "arn:aws:rds:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:pg:${var.application}-${statement.value.name}-*"
      ]
    }
  }

  dynamic "statement" {
    for_each = var.environments
    content {
      actions = [
        "rds:CreateDBSubnetGroup",
        "rds:AddTagsToResource",
        "rds:DescribeDBSubnetGroups",
        "rds:ListTagsForResource",
        "rds:DeleteDBSubnetGroup",
        "rds:CreateDBInstance"
      ]
      resources = [
        "arn:aws:rds:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:subgrp:${var.application}-${statement.value.name}-*"
      ]
    }
  }

  statement {
    actions = [
      "rds:DescribeDBInstances"
    ]
    resources = [
      "arn:aws:rds:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:db:*"
    ]
  }

  dynamic "statement" {
    for_each = var.environments
    content {
      actions = [
        "rds:CreateDBInstance",
        "rds:AddTagsToResource",
        "rds:ModifyDBInstance"
      ]
      resources = [
        "arn:aws:rds:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:db:${var.application}-${statement.value.name}-*"
      ]
    }
  }

  statement {
    actions = [
      "secretsmanager:*",
      "kms:*"
    ]
    resources = [
      "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:rds*"
    ]
  }
}

data "aws_iam_policy_document" "s3" {
  statement {
    actions = [
      "iam:ListAccountAliases"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "s3:*"
    ]
    resources = [
      "arn:aws:s3:::*"
    ]
  }
}

data "aws_iam_policy_document" "opensearch" {
  statement {
    actions = [
      "es:CreateElasticsearchDomain",
      "es:AddTags",
      "es:DescribeDomain",
      "es:DescribeDomainConfig",
      "es:ListTags",
      "es:DeleteDomain",
      "es:UpdateDomainConfig"
    ]
    resources = [
      "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/*"
    ]
  }
}

# Policies for AWS Copilot
data "aws_iam_policy_document" "copilot_assume_role" {
  dynamic "statement" {
    for_each = var.environments
    content {
      actions = [
        "sts:AssumeRole"
      ]
      resources = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.application}-${statement.value.name}-EnvManagerRole"
      ]
    }
  }
}

data "aws_iam_policy_document" "cloudformation" {
  statement {
    actions = [
      "cloudformation:GetTemplateSummary",
      "cloudformation:DescribeStackSet",
      "cloudformation:UpdateStackSet",
      "cloudformation:DescribeStackSetOperation",
      "cloudformation:ListStackInstances",
      "cloudformation:DescribeStacks",
    ]
    resources = [
      "arn:aws:cloudformation:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stack/${var.application}-*",
      "arn:aws:cloudformation:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stack/StackSet-${var.application}-infrastructure-*",
      "arn:aws:cloudformation:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stackset/${var.application}-infrastructure:*",
    ]
  }
}

resource "aws_iam_policy" "cloudformation" {
  name        = "cloudformation-access"
  path        = "/${var.application}/codebuild/"
  description = "Allow ${var.application} codebuild job to access cloudformation resources"
  policy      = data.aws_iam_policy_document.cloudformation.json
}

# Roles
resource "aws_iam_role" "environment_pipeline_codepipeline" {
  name               = "${var.application}-environment-pipeline-codepipeline"
  assume_role_policy = data.aws_iam_policy_document.assume_codepipeline_role.json
  tags               = local.tags
}

resource "aws_iam_role" "environment_pipeline_codebuild" {
  name               = "${var.application}-environment-pipeline-codebuild"
  assume_role_policy = data.aws_iam_policy_document.assume_codebuild_role.json
  managed_policy_arns = [
    aws_iam_policy.cloudformation.arn
  ]
  tags = local.tags
}

# Inline policies
resource "aws_iam_role_policy" "artifact_store_access_for_environment_codepipeline" {
  name   = "${var.application}-artifact-store-access-for-environment-codepipeline"
  role   = aws_iam_role.environment_pipeline_codepipeline.name
  policy = data.aws_iam_policy_document.access_artifact_store.json
}

resource "aws_iam_role_policy" "artifact_store_access_for_environment_codebuild" {
  name   = "${var.application}-artifact-store-access-for-environment-codebuild"
  role   = aws_iam_role.environment_pipeline_codebuild.name
  policy = data.aws_iam_policy_document.access_artifact_store.json
}

resource "aws_iam_role_policy" "log_access_for_environment_codebuild" {
  name   = "${var.application}-log-access-for-environment-codebuild"
  role   = aws_iam_role.environment_pipeline_codebuild.name
  policy = data.aws_iam_policy_document.write_environment_pipeline_codebuild_logs.json
}

# Terraform state access
resource "aws_iam_role_policy" "state_bucket_access_for_environment_codebuild" {
  name   = "${var.application}-state-bucket-access-for-environment-codebuild"
  role   = aws_iam_role.environment_pipeline_codebuild.name
  policy = data.aws_iam_policy_document.state_bucket_access.json
}

resource "aws_iam_role_policy" "state_kms_key_access_for_environment_codebuild" {
  name   = "${var.application}-state-kms-key-access-for-environment-codebuild"
  role   = aws_iam_role.environment_pipeline_codebuild.name
  policy = data.aws_iam_policy_document.state_kms_key_access.json
}

resource "aws_iam_role_policy" "state_dynamo_db_access_for_environment_codebuild" {
  name   = "${var.application}-state-dynamo-db-access-for-environment-codebuild"
  role   = aws_iam_role.environment_pipeline_codebuild.name
  policy = data.aws_iam_policy_document.state_dynamo_db_access.json
}

# VPC and Subnets
resource "aws_iam_role_policy" "ec2_read_access_for_environment_codebuild" {
  name   = "${var.application}-ec2-read-access-for-environment-codebuild"
  role   = aws_iam_role.environment_pipeline_codebuild.name
  policy = data.aws_iam_policy_document.ec2_read_access.json
}

resource "aws_iam_role_policy" "ssm_read_access_for_environment_codebuild" {
  name   = "${var.application}-ssm-read-access-for-environment-codebuild"
  role   = aws_iam_role.environment_pipeline_codebuild.name
  policy = data.aws_iam_policy_document.ssm_read_access.json
}

# Assume DNS account role
resource "aws_iam_role_policy" "dns_account_assume_role_for_environment_codebuild" {
  name   = "${var.application}-dns-account-assume-role-for-environment-codebuild"
  role   = aws_iam_role.environment_pipeline_codebuild.name
  policy = data.aws_iam_policy_document.dns_account_assume_role.json
}

resource "aws_iam_role_policy" "load_balancer_for_environment_codebuild" {
  name   = "${var.application}-load-balancer-for-environment-codebuild"
  role   = aws_iam_role.environment_pipeline_codebuild.name
  policy = data.aws_iam_policy_document.load_balancer.json
}

resource "aws_iam_role_policy" "certificate_for_environment_codebuild" {
  name   = "${var.application}-certificate-for-environment-codebuild"
  role   = aws_iam_role.environment_pipeline_codebuild.name
  policy = data.aws_iam_policy_document.certificate.json
}

resource "aws_iam_role_policy" "security_group_for_environment_codebuild" {
  name   = "${var.application}-security-group-for-environment-codebuild"
  role   = aws_iam_role.environment_pipeline_codebuild.name
  policy = data.aws_iam_policy_document.security_group.json
}

resource "aws_iam_role_policy" "ssm_parameter_for_environment_codebuild" {
  name   = "${var.application}-ssm-parameter-for-environment-codebuild"
  role   = aws_iam_role.environment_pipeline_codebuild.name
  policy = data.aws_iam_policy_document.ssm_parameter.json
}

resource "aws_iam_role_policy" "cloudwatch_for_environment_codebuild" {
  name   = "${var.application}-cloudwatch-for-environment-codebuild"
  role   = aws_iam_role.environment_pipeline_codebuild.name
  policy = data.aws_iam_policy_document.cloudwatch.json
}

resource "aws_iam_role_policy" "logs_for_environment_codebuild" {
  name   = "${var.application}-logs-for-environment-codebuild"
  role   = aws_iam_role.environment_pipeline_codebuild.name
  policy = data.aws_iam_policy_document.logs.json
}

resource "aws_iam_role_policy" "kms_key_for_environment_codebuild" {
  name   = "${var.application}-kms-key-for-environment-codebuild"
  role   = aws_iam_role.environment_pipeline_codebuild.name
  policy = data.aws_iam_policy_document.kms_key.json
}

resource "aws_iam_role_policy" "redis_for_environment_codebuild" {
  name   = "${var.application}-redis-for-environment-codebuild"
  role   = aws_iam_role.environment_pipeline_codebuild.name
  policy = data.aws_iam_policy_document.redis.json
}

resource "aws_iam_role_policy" "postgres_for_environment_codebuild" {
  name   = "${var.application}-postgres-for-environment-codebuild"
  role   = aws_iam_role.environment_pipeline_codebuild.name
  policy = data.aws_iam_policy_document.postgres.json
}

resource "aws_iam_role_policy" "s3_for_environment_codebuild" {
  name   = "${var.application}-s3-for-environment-codebuild"
  role   = aws_iam_role.environment_pipeline_codebuild.name
  policy = data.aws_iam_policy_document.s3.json
}

resource "aws_iam_role_policy" "opensearch_for_environment_codebuild" {
  name   = "${var.application}-opensearch-for-environment-codebuild"
  role   = aws_iam_role.environment_pipeline_codebuild.name
  policy = data.aws_iam_policy_document.opensearch.json
}

resource "aws_iam_role_policy" "copilot_assume_role_for_environment_codebuild" {
  name   = "${var.application}-copilot-assume-role-for-environment-codebuild"
  role   = aws_iam_role.environment_pipeline_codebuild.name
  policy = data.aws_iam_policy_document.copilot_assume_role.json
}
