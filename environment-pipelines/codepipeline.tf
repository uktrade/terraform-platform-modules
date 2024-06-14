data "aws_codestarconnections_connection" "github_codestar_connection" {
  name = var.application
}

resource "aws_codepipeline" "environment_pipeline" {
  name          = "${var.application}-${var.pipeline_name}-environment-pipeline"
  role_arn      = aws_iam_role.environment_pipeline_codepipeline.arn
  depends_on    = [aws_iam_role_policy.artifact_store_access_for_environment_codebuild]
  pipeline_type = "V2"

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
      name             = "GitCheckout"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["project_deployment_source"]

      configuration = {
        ConnectionArn    = data.aws_codestarconnections_connection.github_codestar_connection.arn
        FullRepositoryId = var.repository
        BranchName       = var.branch
        DetectChanges    = var.trigger_on_push
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "InstallTools"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["project_deployment_source"]
      output_artifacts = ["build_output"]
      version          = "1"
      namespace        = "slack"

      configuration = {
        ProjectName   = "${var.application}-${var.pipeline_name}-environment-pipeline-build"
        PrimarySource = "project_deployment_source"
        EnvironmentVariables : jsonencode([
          { name : "APPLICATION", value : var.application },
          { name : "REPOSITORY", value : var.repository },
          { name : "SLACK_CHANNEL_ID", value : var.slack_channel, type : "PARAMETER_STORE" },
        ])
      }
    }
  }

  dynamic "stage" {
    for_each = local.stages
    content {
      name = stage.value.stage_name

      action {
        name             = stage.value.name
        category         = stage.value.category
        owner            = stage.value.owner
        provider         = stage.value.provider
        input_artifacts  = stage.value.input_artifacts
        output_artifacts = stage.value.output_artifacts
        version          = "1"
        configuration    = stage.value.configuration
        namespace        = stage.value.namespace
      }
    }
  }

  tags = local.tags
}

module "artifact_store" {
  source = "../s3"

  application = var.application
  environment = "not-applicable"
  name        = "${var.application}-${var.pipeline_name}-environment-pipeline-artifact-store"

  config = {
    bucket_name = "${var.application}-${var.pipeline_name}-environment-pipeline-artifact-store"
  }
}
