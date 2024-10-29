data "aws_caller_identity" "current" {}

data "aws_kms_key" "data_dump_kms_key" {
  key_id = local.dump_kms_key_alias
}

data "aws_s3_bucket" "data_dump_bucket" {
  bucket = local.dump_bucket_name
}

data "aws_iam_policy_document" "allow_task_creation" {
  statement {
    sid    = "AllowPullFromEcr"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
    ]
    resources = [local.ecr_repository_arn]
  }

  statement {
    sid    = "AllowLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:eu-west-2:${data.aws_caller_identity.current.account_id}:log-group:/ecs/${local.task_name}",
      "arn:aws:logs:eu-west-2:${data.aws_caller_identity.current.account_id}:log-group:/ecs/${local.task_name}:log-stream:*",
    ]
  }
}

data "aws_iam_policy_document" "assume_ecs_task_role" {
  policy_id = "assume_ecs_task_role"
  statement {
    sid    = "AllowECSAssumeRole"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "data_load_task_execution_role" {
  name               = "${local.task_name}-exec"
  assume_role_policy = data.aws_iam_policy_document.assume_ecs_task_role.json

  tags = local.tags
}

resource "aws_iam_role_policy" "allow_task_creation" {
  name   = "AllowTaskCreation"
  role   = aws_iam_role.data_load_task_execution_role.name
  policy = data.aws_iam_policy_document.allow_task_creation.json
}

data "aws_iam_policy_document" "data_load" {
  # checkov:skip=CKV_AWS_356:Permissions required to upload
  policy_id = "data_load"
  statement {
    sid    = "AllowReadFromS3"
    effect = "Allow"

    actions = local.s3_permissions

    resources = [
      data.aws_s3_bucket.data_dump_bucket.arn,
      "${data.aws_s3_bucket.data_dump_bucket.arn}/*"
    ]
  }

  statement {
    sid    = "AllowKMSDencryption"
    effect = "Allow"

    actions = [
      "kms:Decrypt",
    ]

    resources = [data.aws_kms_key.data_dump_kms_key.arn]
  }
}

resource "aws_iam_role" "data_load" {
  name               = "${local.task_name}-task"
  assume_role_policy = data.aws_iam_policy_document.assume_ecs_task_role.json

  tags = local.tags
}

resource "aws_iam_role_policy" "allow_data_load" {
  name   = "AllowDataLoad"
  role   = aws_iam_role.data_load.name
  policy = data.aws_iam_policy_document.data_load.json
}

resource "aws_ecs_task_definition" "service" {
  family = local.task_name
  container_definitions = jsonencode([
    {
      name      = local.task_name
      image     = "public.ecr.aws/uktrade/database-copy:latest"
      essential = true
      environment = [
        {
          name  = "DB_CONNECTION_STRING"
          value = "provided during task creation"
        },
        {
          name  = "DATA_COPY_OPERATION"
          value = "LOAD"
        },
        {
          name  = "S3_BUCKET_NAME"
          value = data.aws_s3_bucket.data_dump_bucket.bucket
        }
      ],
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = "/ecs/${local.task_name}"
          awslogs-region        = "eu-west-2"
          mode                  = "non-blocking"
          awslogs-create-group  = "true"
          max-buffer-size       = "25m"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  cpu    = 1024
  memory = 3072


  requires_compatibilities = ["FARGATE"]

  task_role_arn      = aws_iam_role.data_load.arn
  execution_role_arn = aws_iam_role.data_load_task_execution_role.arn
  network_mode       = "awsvpc"

  runtime_platform {
    cpu_architecture        = "ARM64"
    operating_system_family = "LINUX"
  }
}
