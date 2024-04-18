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
        ProjectName = "${var.application}-environment-terraform"
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

