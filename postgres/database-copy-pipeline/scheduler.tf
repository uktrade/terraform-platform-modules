resource "aws_scheduler_schedule" "database_pipeline_schedule" {
  name = local.pipeline_name

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "cron(${var.task.pipeline.schedule})"

  target {
    arn      = aws_codepipeline.database_copy_pipeline.arn
    role_arn = aws_iam_role.database_pipeline_schedule.arn
  }
}

resource "aws_iam_role" "database_pipeline_schedule" {
  name               = "${local.pipeline_name}-scheduler"
  assume_role_policy = data.aws_iam_policy_document.assume_database_pipeline_scheduler_role.json
  tags               = local.tags
}

resource "aws_iam_role_policy" "database_pipeline_schedule" {
  name   = "${local.pipeline_name}-scheduler-access"
  role   = aws_iam_role.database_pipeline_schedule.name
  policy = data.aws_iam_policy_document.pipeline_access_for_database_pipeline_scheduler.json
}

data "aws_iam_policy_document" "assume_database_pipeline_scheduler_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "pipeline_access_for_database_pipeline_scheduler" {
  statement {
    effect = "Allow"
    actions = [
      "codepipeline:StartPipelineExecution"
    ]
    resources = [
      "arn:aws:codepipeline:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${local.pipeline_name}"
    ]
  }
}
