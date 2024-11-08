resource "aws_codepipeline" "environment_pipeline" {
  for_each      = toset(var.pipelines)
  name          = "${var.application}-${var.codebase}-${each.value}-pipeline"
  role_arn      = aws_iam_role.codebase_deploy_pipeline.arn
  depends_on = [aws_iam_role_policy.artifact_store_access_for_codebase_pipeline]
  pipeline_type = "V2"

  variable {
    name          = "IMAGE_TAG"
    default_value = each.value.tag ? "tag-latest" : each.value.branch
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
    name = "Create-Deploy-Manifests"

    action {
      name     = "CreateManifests"
      category = "Build"
      owner    = "AWS"
      provider = "CodeBuild"
      output_artifacts = ["manifest_output"]
      version  = "1"

      configuration = {
        ProjectName = "${var.application}-${var.codebase}-codebase-pipeline-manifests"
        EnvironmentVariables : jsonencode([
          { name : "APPLICATION", value : var.application },
          { name : "ENVIRONMENTS", value : [for env in each.value.environments : env.name] },
          { name : "SERVICES", value : local.services },
          { name : "IMAGE_TAG", value : "#{variables.IMAGE_TAG}" }
        ])
      }
    }
  }

  dynamic "stage" {
    for_each = each.value.environments
    content {
      name = stage.value.name

      dynamic "action" {
        for_each = local.run_groups
        content {
          name      = action.value
          category  = "Deploy"
          owner     = "AWS"
          provider  = "ECS"
          version   = "1"
          input_artifacts = ["manifest_output"]
          run_order = action.key + 1
        }
      }
    }
  }

  tags = local.tags
}