data "aws_codestarconnections_connection" "github_codestar_connection" {
  name = var.application
}

resource "aws_codepipeline" "environment_pipeline" {
  name       = "${var.application}-environment-pipeline"
  role_arn   = aws_iam_role.environment_pipeline_codepipeline.arn
  depends_on = [aws_iam_role_policy.artifact_store_access_for_environment_codebuild]

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

        configuration = {
          ProjectName   = "${var.application}-environment-pipeline"
          PrimarySource = "project_deployment_source"
        }
    }
  }

  stage {
    name = "tf-plan-dev"

    action {
      name             = "tf-plan-dev"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["build_output"]
      output_artifacts = ["deploy_output"]
      version          = "1"

        configuration = {
          ProjectName = "${var.application}-environment-pipeline-tf-plan"
          PrimarySource = "build_output"
          EnvironmentVariables = jsonencode([
            {
              name  = "ENVIRONMENT"
              value = "dev"
            }
          ])
        }
    }
  }

#   dynamic "stage" {
#     for_each = local.stages
#     content {
#       name = "Build"
#
#       action {
#         name             = "InstallTools"
#         category         = "Build"
#         owner            = "AWS"
#         provider         = "CodeBuild"
#         input_artifacts  = ["project_deployment_source"]
#         output_artifacts = ["build_output"]
#         version          = "1"
#
#           configuration = {
#             ProjectName = "${var.application}-environment-pipeline"
#             PrimarySource = "project_deployment_source"
#             EnvironmentVariables = jsonencode([
#               {
#                 name  = "ENVIRONMENT"
#                 value = stage.value.env
#               }
#             ])
#           }
#         }
#     }
#   }

  tags = local.tags
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
