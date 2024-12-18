resource "aws_codepipeline" "codebase_pipeline" {
  for_each       = local.pipeline_map
  name           = "${var.application}-${var.codebase}-${each.value.name}-codebase-pipeline"
  role_arn       = aws_iam_role.codebase_deploy_pipeline.arn
  depends_on     = [aws_iam_role_policy.artifact_store_access_for_codebase_pipeline]
  pipeline_type  = "V2"
  execution_mode = "QUEUED"

  variable {
    name          = "IMAGE_TAG"
    default_value = coalesce(each.value.tag, false) ? "tag-latest" : "branch-${each.value.branch}"
    description   = "Tagged image in ECR to deploy"
  }

  artifact_store {
    location = aws_s3_bucket.artifact_store.bucket
    type     = "S3"

    encryption_key {
      id   = aws_kms_key.artifact_store_kms_key.arn
      type = "KMS"
    }
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "ECR"
      version          = "1"
      namespace        = "source_ecr"
      output_artifacts = ["source_output"]

      configuration = {
        RepositoryName = local.ecr_name
        ImageTag       = coalesce(each.value.tag, false) ? "tag-latest" : "branch-${each.value.branch}"
      }
    }
  }

  dynamic "stage" {
    for_each = each.value.environments
    content {
      name = "Deploy-${stage.value.name}"

      dynamic "action" {
        for_each = coalesce(stage.value.requires_approval, false) ? [1] : []
        content {
          name      = "Approve-${stage.value.name}"
          category  = "Approval"
          owner     = "AWS"
          provider  = "Manual"
          version   = "1"
          run_order = 1
        }
      }

      dynamic "action" {
        for_each = local.service_order_list
        content {
          name             = action.value.name
          category         = "Build"
          owner            = "AWS"
          provider         = "CodeBuild"
          input_artifacts  = ["source_output"]
          output_artifacts = []
          version          = "1"
          run_order        = action.value.order + 1

          configuration = {
            ProjectName = aws_codebuild_project.codebase_deploy.name
            EnvironmentVariables : jsonencode([
              { name : "APPLICATION", value : var.application },
              { name : "ENVIRONMENT", value : stage.value.name },
              { name : "SERVICE", value : action.value.name },
              { name : "REPOSITORY_URL", value : local.repository_url },
              { name : "IMAGE_TAG", value : "#{variables.IMAGE_TAG}" }
            ])
          }
        }
      }
    }
  }

  tags = local.tags
}


resource "aws_codepipeline" "manual_release_pipeline" {
  name           = "${var.application}-${var.codebase}-manual-release-pipeline"
  role_arn       = aws_iam_role.codebase_deploy_pipeline.arn
  pipeline_type  = "V2"
  execution_mode = "QUEUED"

  variable {
    name          = "IMAGE_TAG"
    default_value = "NONE"
    description   = "Tagged image in ECR to deploy"
  }

  variable {
    name          = "ENVIRONMENT"
    default_value = "NONE"
    description   = "Name of the environment to deploy to"
  }

  artifact_store {
    location = aws_s3_bucket.artifact_store.bucket
    type     = "S3"

    encryption_key {
      id   = aws_kms_key.artifact_store_kms_key.arn
      type = "KMS"
    }
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "ECR"
      version          = "1"
      namespace        = "source_ecr"
      output_artifacts = ["source_output"]

      configuration = {
        RepositoryName = local.ecr_name
      }
    }
  }

  stage {
    name = "Deploy"

    dynamic "action" {
      for_each = local.service_order_list
      content {
        name             = action.value.name
        category         = "Build"
        owner            = "AWS"
        provider         = "CodeBuild"
        input_artifacts  = ["source_output"]
        output_artifacts = []
        version          = "1"
        run_order        = action.value.order + 1

        configuration = {
          ProjectName = aws_codebuild_project.codebase_deploy.name
          EnvironmentVariables : jsonencode([
            { name : "APPLICATION", value : var.application },
            { name : "ENVIRONMENT", value : "#{variables.ENVIRONMENT}" },
            { name : "SERVICE", value : action.value.name },
            { name : "REPOSITORY_URL", value : local.repository_url },
            { name : "IMAGE_TAG", value : "#{variables.IMAGE_TAG}" }
          ])
        }
      }
    }
  }

  tags = local.tags
}
