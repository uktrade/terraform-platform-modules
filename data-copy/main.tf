resource "aws_ecs_task_definition" "service" {
  family = "${var.application}-${var.environment}-${var.name}-data-dump"
  container_definitions = jsonencode([
    {
      name        = "data-dump"
      image       = "public.ecr.aws/uktrade/database-copy:latest"
      essential   = true
      environment = [
        {
          name  = "DB_CONNECTION_STRING"
          value = "provided during task creation"
        }
      ],
      port_mappings = [
        {
          container_port = 80
          host_port      = 80
        }
      ]
      log_configuration = {
        log_driver = "awslogs",
        options   = {
          awslogs_group         = "/ecs/${var.application}-${var.environment}-${var.name}-data-copy"
          mode                  = "non-blocking"
          awslogs_create_group  = "true"
          max_buffer_size       = "25m"
          awslogs_stream_prefix = "ecs"
        }
      }
    }
  ])

  cpu  = 1024
  memory = 3072

  volume {
    name      = "service-storage"
    host_path = "/ecs/service-storage"
  }

  requires_compatibilities = [ "FARGATE" ]

  task_role_arn = "arn:aws:iam::891377058512:role/data-copy-poc-ant-s3-access"
  execution_role_arn = "arn:aws:iam::891377058512:role/ecsTaskExecutionRole"
  network_mode = "awsvpc"

  runtime_platform = {
    cpu_architecture = "ARM64"
    operating_system_family = "LINUX"
  }
}


resource "aws_s3_bucket" "data_copy_bucket" {
  # checkov:skip=CKV_AWS_144: Cross Region Replication not Required
  # checkov:skip=CKV2_AWS_62: Requires wider discussion around log/event ingestion before implementing. To be picked up on conclusion of DBTP-974
  # checkov:skip=CKV2_AWS_61: This bucket is used for ephemeral data transfer - we do not need lifecycle configuration
  # checkov:skip=CKV_AWS_21: This bucket is used for ephemeral data transfer - we do not want versioning
  # checkov:skip=CKV_AWS_18:  Requires wider discussion around log/event ingestion before implementing. To be picked up on conclusion of DBTP-974
  bucket = "${var.application}-${var.pipeline_name}-data-copy"

  tags = local.tags
}

data "aws_iam_policy_document" "data_copy_bucket_policy" {
  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:*",
    ]

    effect = "Deny"

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"

      values = [
        "false",
      ]
    }

    resources = [
      aws_s3_bucket.data_copy_bucket.arn,
      "${aws_s3_bucket.data_copy_bucket.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "data_copy_bucket_policy" {
  bucket = aws_s3_bucket.data_copy_bucket.id
  policy = data.aws_iam_policy_document.data_copy_bucket_policy.json
}

resource "aws_kms_key" "data_copy_kms_key" {
  # checkov:skip=CKV_AWS_7:We are not currently rotating the keys
  description = "KMS Key for S3 encryption"
  tags        = local.tags

  policy = jsonencode({
    Id = "key-default-1"
    Statement = [
      {
        "Sid" : "Enable IAM User Permissions",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        "Action" : "kms:*",
        "Resource" : "*"
      }
    ]
    Version = "2012-10-17"
  })
}

resource "aws_kms_alias" "data_copy_kms_alias" {
  depends_on    = [aws_kms_key.data_copy_kms_key]
  name          = "alias/${var.application}-${var.pipeline_name}-data-copy-key"
  target_key_id = aws_kms_key.data_copy_kms_key.id
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption-config" {
  # checkov:skip=CKV2_AWS_67:We are not currently rotating the keys
  bucket = aws_s3_bucket.data_copy_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.data_copy_kms_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket                  = aws_s3_bucket.data_copy_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "data_upload" {
  # checkov:skip=CKV_AWS_356:Permissions required to upload
  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:PutObjectTagging",
      "s3:GetObjectTagging",
      "s3:GetObjectVersion",
      "s3:GetObjectVersionTagging"
    ]

    resources = [
      aws_s3_bucket.data_copy_bucket.arn,
      "${aws_s3_bucket.data_copy_bucket.arn}/*"
    ]
  }

  statement {
    sid    = "AllowKMSEncryption"
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
    ]

    resources = [var.destination_kms_key_arn]
  }
}

data "aws_iam_policy_document" "data_download" {
  # checkov:skip=CKV_AWS_356:Permissions required to upload
  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:GetObjectTagging",
      "s3:GetObjectVersion",
      "s3:GetObjectVersionTagging"
    ]

    resources = [
      aws_s3_bucket.data_copy_bucket.arn,
      "${aws_s3_bucket.data_copy_bucket.arn}/*"
    ]
  }

  statement {
      sid    = "AllowKMSDecryption"
      effect = "Allow"

      actions = [
        "kms:Decrypt",
        "kms:DescribeKey"
      ]

      resources = [var.config.source_kms_key_arn]
  }
}

data "aws_iam_policy_document" "allow_task_creation" {
  statement {
    effect = "Allow"
    action = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = "*"
  }
}

resource "aws_iam_role" "data_upload_ecs_task_role" {
  name               = "${var.name}-${var.application}-${var.environment}-data-copy-ecs-task"
  assume_role_policy = data.aws_iam_policy_document.assume_ecstask_role.json

  inline_policy {
    name   = "AllowDataUpload"
    policy = data.aws_iam_policy_document.data_upload.json
  }

  tags = local.tags
}

data "aws_iam_policy_document" "assume_ecstask_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}
