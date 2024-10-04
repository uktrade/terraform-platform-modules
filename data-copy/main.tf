data "aws_caller_identity" "current" {}

# ================================================
# Configuration required by both sides of the copy
# ================================================

data "aws_iam_policy_document" "allow_task_creation" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
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

resource "aws_iam_role" "start_ecs_task_role" {
  name               = "${var.application}-${var.environment}-${local.dump_task_name}-task-role"
  assume_role_policy = data.aws_iam_policy_document.assume_ecstask_role.json

  inline_policy {
    name   = "AllowTaskCreation"
    policy = data.aws_iam_policy_document.allow_task_creation.json
  }

  tags = local.tags
}

data "aws_iam_policy_document" "data_copy" {
  # checkov:skip=CKV_AWS_356:Permissions required to upload
  statement {
    effect = "Allow"

    actions = local.s3_permissions

    resources = [
      "arn:aws:s3:::${var.application}-${local.dump_task_name}",
      "arn:aws:s3:::${var.application}-${local.dump_task_name}/*"
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

    resources = [aws_kms_key.data_copy_kms_key.arn]
  }
}


# data "aws_iam_policy_document" "data_restore" {
#   depends_on = [aws_kms_key.data_copy_kms_key]
  
#   # checkov:skip=CKV_AWS_356:Permissions required to upload
#   statement {
#     effect = "Allow"

#     actions = local.s3_permissions

#     resources = [
#       "arn:aws:s3:::${var.application}-${local.dump_task_name}",
#       "arn:aws:s3:::${var.application}-${local.dump_task_name}/*"
#     ]
#   }

#   statement {
#     sid    = "AllowKMSEncryption"
#     effect = "Allow"

#     actions = [
#       "kms:Decrypt",
#     ]

#     resources = [
#       data.aws_kms_key.data_copy_kms_key.arn
#     ]
#   }
# }


# data "aws_kms_key" "data_copy_kms_key" {
#   key_id = "alias/${var.application}-${local.dump_task_name}-key"
# }


resource "aws_iam_role" "data_copy" {
  name               = "${var.application}-${var.environment}-${local.dump_task_name}-data-copy"
  assume_role_policy = data.aws_iam_policy_document.assume_ecstask_role.json

  inline_policy {
    name   = "AllowDataUpload"
    policy = data.aws_iam_policy_document.data_copy.json
  }

  tags = local.tags
}


resource "aws_ecs_task_definition" "service" {
  family = local.task_family
  container_definitions = jsonencode([
    {
      name      = "data-${local.task_type}"
      image     = "public.ecr.aws/uktrade/database-copy:latest"
      essential = true
      environment = [
        {
          name  = "DB_CONNECTION_STRING"
          value = "provided during task creation"
        },
        {
          name  = "DATA_COPY_OPERATION"
          value = local.is_data_dump ? "DUMP" : "RESTORE"
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
        options = {
          awslogs_group         = "/ecs/${var.application}-${var.environment}-${local.task_name}"
          mode                  = "non-blocking"
          awslogs_create_group  = "true"
          max_buffer_size       = "25m"
          awslogs_stream_prefix = "ecs"
        }
      }
    }
  ])

  cpu    = 1024
  memory = 3072


  requires_compatibilities = ["FARGATE"]

  task_role_arn      = aws_iam_role.start_ecs_task_role.arn
  execution_role_arn = aws_iam_role.start_ecs_task_role.arn
  network_mode       = "awsvpc"

  runtime_platform {
    cpu_architecture        = "ARM64"
    operating_system_family = "LINUX"
  }
}

#################################################################################################
## Configuration for the bucket. Only needs doing once, so we'll do it in the "from" environment.
#################################################################################################

resource "aws_s3_bucket" "data_copy_bucket" {
  # checkov:skip=CKV_AWS_144: Cross Region Replication not Required
  # checkov:skip=CKV2_AWS_62: Requires wider discussion around log/event ingestion before implementing. To be picked up on conclusion of DBTP-974
  # checkov:skip=CKV2_AWS_61: This bucket is used for ephemeral data transfer - we do not need lifecycle configuration
  # checkov:skip=CKV_AWS_21: This bucket is used for ephemeral data transfer - we do not want versioning
  # checkov:skip=CKV_AWS_18:  Requires wider discussion around log/event ingestion before implementing. To be picked up on conclusion of DBTP-974
  # count  = local.is_data_dump ? 1 : 0
  bucket = "${var.application}-${local.dump_task_name}"

  tags = local.tags
}

data "aws_iam_policy_document" "data_copy_bucket_policy" {
  # count = local.is_data_dump ? 1 : 0
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
  # count  = local.is_data_dump ? 1 : 0
  bucket = aws_s3_bucket.data_copy_bucket.id
  policy = data.aws_iam_policy_document.data_copy_bucket_policy.json
}

resource "aws_kms_key" "data_copy_kms_key" {
  # count = local.is_data_dump ? 1 : 0
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
  # count         = local.is_data_dump ? 1 : 0
  depends_on    = [aws_kms_key.data_copy_kms_key]
  name          = "alias/${var.application}-${local.dump_task_name}"
  target_key_id = aws_kms_key.data_copy_kms_key.id
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption-config" {
  # checkov:skip=CKV2_AWS_67:We are not currently rotating the keys
  # count  = local.is_data_dump ? 1 : 0
  bucket = aws_s3_bucket.data_copy_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.data_copy_kms_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "public_access_block" {
  # count                   = local.is_data_dump ? 1 : 0
  bucket                  = aws_s3_bucket.data_copy_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
