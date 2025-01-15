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
      name             = "GitCheckout"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["deploy_source"]

      configuration = {
        ConnectionArn    = data.aws_codestarconnections_connection.github_codestar_connection.arn
        FullRepositoryId = "${var.repository}-deploy"
        BranchName       = "main"
        DetectChanges    = false
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
          input_artifacts  = ["deploy_source"]
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
              { name : "REPOSITORY_NAME", value : local.ecr_name },
              { name : "PREFIXED_REPOSITORY_NAME", value : local.prefixed_repository_name },
              { name : "IMAGE_TAG", value : "#{variables.IMAGE_TAG}" },
              { name : "AWS_REGION", value : local.aws_region },
              { name : "AWS_ACCOUNT_ID", value : local.aws_account_id }
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
      name             = "GitCheckout"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["deploy_source"]

      configuration = {
        ConnectionArn    = data.aws_codestarconnections_connection.github_codestar_connection.arn
        FullRepositoryId = "${var.repository}-deploy"
        BranchName       = "main"
        DetectChanges    = false
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
        input_artifacts  = ["deploy_source"]
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
            { name : "REPOSITORY_NAME", value : local.ecr_name },
            { name : "IMAGE_TAG", value : "#{variables.IMAGE_TAG}" }
          ])
        }
      }
    }
  }

  tags = local.tags
}

# This is a temporary workaround until automatic stage rollback is implemented in terraform-provider-aws
# https://github.com/hashicorp/terraform-provider-aws/issues/37244
resource "terraform_data" "update_pipeline" {
  provisioner "local-exec" {
    command = "python ${path.module}/custom_pipeline_update/update_pipeline.py"
    quiet   = true
    environment = {
      PIPELINES = jsonencode(local.pipeline_names)
    }
  }
  triggers_replace = [
    aws_codepipeline.codebase_pipeline,
    aws_codepipeline.manual_release_pipeline,
    file("${path.module}/custom_pipeline_update/update_pipeline.py")
  ]
  depends_on = [
    aws_codepipeline.codebase_pipeline,
    aws_codepipeline.manual_release_pipeline
  ]
}
