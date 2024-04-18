resource "aws_codepipeline" "codepipeline" {
  name     = "${var.application}-environment-pipeline"
  role_arn = aws_iam_role.environment_pipeline_role.arn

  artifact_store {
    location = module.artifact_store.bucket_name
    type     = "S3"

    encryption_key {
      id   = module.artifact_store.kms_key_arn
      type = "KMS"
    }
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = data.aws_codestarconnections_connection.github_codestar_connection.arn
        FullRepositoryId = var.repository
        BranchName       = "main"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = "test"
      }
    }
  }

  tags = local.tags
}

data "aws_codestarconnections_connection" "github_codestar_connection" {
  name = var.application
}

module "artifact_store" {
  source = "../s3"

  application = var.application
  environment = "not-applicable"
  name        = "${var.application}-environment-pipeline-artifact-store"

  config = {
    bucket_name = "${var.application}-environment-pipeline-artifact-store"
  }
}

#resource "aws_s3_bucket_public_access_block" "codepipeline_bucket_pab" {
#  bucket = module.artifact_store.id
#
#  block_public_acls       = true
#  block_public_policy     = true
#  ignore_public_acls      = true
#  restrict_public_buckets = true
#}

resource "aws_iam_role" "environment_pipeline_role" {
  name               = "${var.application}-environment-pipeline-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = local.tags
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "codepipeline_policy" {
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

resource "aws_iam_role_policy" "codepipeline_policy" {
  name   = "codepipeline_policy"
  role   = aws_iam_role.environment_pipeline_role.id
  policy = data.aws_iam_policy_document.codepipeline_policy.json
}
