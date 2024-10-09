

data "aws_kms_key" "data_dump_kms_key" {
  key_id = local.dump_kms_key_alias
}

data "aws_s3_bucket" "data_dump_bucket" {
  bucket = local.dump_bucket_name
}

data "aws_iam_policy_document" "allow_task_creation" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "assume_ecs_task_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "data_restore_task_execution_role" {
  name               = "${local.task_name}-exec"
  assume_role_policy = data.aws_iam_policy_document.assume_ecs_task_role.json

  inline_policy {
    name   = "AllowTaskCreation"
    policy = data.aws_iam_policy_document.allow_task_creation.json
  }

  tags = local.tags
}


data "aws_iam_policy_document" "data_restore" {
  # checkov:skip=CKV_AWS_356:Permissions required to upload
  statement {
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


resource "aws_iam_role" "data_restore" {
  name               = "${local.task_name}-data-restore"
  assume_role_policy = data.aws_iam_policy_document.assume_ecs_task_role.json

  inline_policy {
    name   = "AllowDataDownload"
    policy = data.aws_iam_policy_document.data_restore.json
  }

  tags = local.tags
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
          value = "RESTORE"
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

  task_role_arn      = aws_iam_role.data_restore.arn
  execution_role_arn = aws_iam_role.data_restore_task_execution_role.arn
  network_mode       = "awsvpc"

  runtime_platform {
    cpu_architecture        = "ARM64"
    operating_system_family = "LINUX"
  }
}