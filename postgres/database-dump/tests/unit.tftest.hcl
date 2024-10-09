variables {
  application   = "test-app"
  environment   = "test-env"
  database_name = "test-db"
}


run "data_dump_unit_test" {
  command = plan

  assert {
    condition     = contains(jsondecode(data.aws_iam_policy_document.allow_task_creation.json).Statement[0].Action, "ecr:GetAuthorizationToken")
    error_message = "Permission not found: ecr:GetAuthorizationToken"
  }

  assert {
    condition     = contains(jsondecode(data.aws_iam_policy_document.allow_task_creation.json).Statement[0].Action, "ecr:BatchCheckLayerAvailability")
    error_message = "Permission not found: ecr:BatchCheckLayerAvailability"
  }

  assert {
    condition     = contains(jsondecode(data.aws_iam_policy_document.allow_task_creation.json).Statement[0].Action, "ecr:GetDownloadUrlForLayer")
    error_message = "Permission not found: ecr:GetDownloadUrlForLayer"
  }

  assert {
    condition     = contains(jsondecode(data.aws_iam_policy_document.allow_task_creation.json).Statement[0].Action, "ecr:BatchGetImage")
    error_message = "Permission not found: ecr:BatchGetImage"
  }

  assert {
    condition     = contains(jsondecode(data.aws_iam_policy_document.allow_task_creation.json).Statement[0].Action, "logs:CreateLogGroup")
    error_message = "Permission not found: logs:CreateLogGroup"
  }

  assert {
    condition     = contains(jsondecode(data.aws_iam_policy_document.allow_task_creation.json).Statement[0].Action, "logs:CreateLogStream")
    error_message = "Permission not found: logs:CreateLogStream"
  }

  assert {
    condition     = contains(jsondecode(data.aws_iam_policy_document.allow_task_creation.json).Statement[0].Action, "logs:PutLogEvents")
    error_message = "Permission not found: logs:PutLogEvents"
  }

  assert {
    condition     = jsondecode(data.aws_iam_policy_document.assume_ecs_task_role.json).Statement[0].Action == "sts:AssumeRole"
    error_message = "Permission not found: sts:AssumeRole"
  }

  assert {
    condition     = jsondecode(data.aws_iam_policy_document.assume_ecs_task_role.json).Statement[0].Principal.Service == "ecs-tasks.amazonaws.com"
    error_message = "Principal identifier should be: 'ecs-tasks.amazonaws.com'"
  }

  assert {
    condition     = aws_iam_role.data_dump_task_execution_role.name == "test-env-test-db-dump-exec"
    error_message = "Task execution role name should be: 'test-env-test-db-dump-exec'"
  }

  assert {
    condition     = jsondecode(aws_iam_role.data_dump_task_execution_role.assume_role_policy).Statement[0].Sid == "AllowECSAssumeRole"
    error_message = "Statement Sid should be: 'AllowECSAssumeRole'"
  }

  assert {
    condition     = aws_iam_role_policy.allow_task_creation.name == "AllowTaskCreation"
    error_message = "Role policy name should be: 'AllowTaskCreation'"
  }

  assert {
    condition     = aws_iam_role_policy.allow_task_creation.role == "test-env-test-db-dump-exec"
    error_message = "Role name should be: 'test-env-test-db-dump-exec'"
  }

  assert {
    condition     = data.aws_iam_policy_document.data_dump.statement[0].sid == "AllowWriteToS3"
    error_message = "Should be 'AllowWriteToS3'"
  }

  assert {
    condition     = length(data.aws_iam_policy_document.data_dump.statement) == 2
    error_message = "Should be 1 policy statement"
  }

  assert {
    condition     = contains(data.aws_iam_policy_document.data_dump.statement[0].actions, "s3:ListBucket")
    error_message = "Permission not found: s3:ListBucket"
  }

  assert {
    condition     = contains(data.aws_iam_policy_document.data_dump.statement[0].actions, "s3:PutObject")
    error_message = "Permission not found: s3:PutObject"
  }

  assert {
    condition     = contains(data.aws_iam_policy_document.data_dump.statement[0].actions, "s3:PutObjectTagging")
    error_message = "Permission not found: s3:PutObjectTagging"
  }

  assert {
    condition     = contains(data.aws_iam_policy_document.data_dump.statement[0].actions, "s3:GetObjectTagging")
    error_message = "Permission not found: s3:GetObjectTagging"
  }

  assert {
    condition     = contains(data.aws_iam_policy_document.data_dump.statement[0].actions, "s3:GetObjectVersion")
    error_message = "Permission not found: s3:GetObjectVersion"
  }

  assert {
    condition     = contains(data.aws_iam_policy_document.data_dump.statement[0].actions, "s3:GetObjectVersionTagging")
    error_message = "Permission not found: s3:GetObjectVersionTagging"
  }

  assert {
    condition     = length(data.aws_iam_policy_document.data_dump.statement[0].actions) == 7
    error_message = "Should be 7 permissions on policy statement"
  }

  #  data.aws_iam_policy_document.data_dump.statement[0].resources cannot be tested on a 'plan'

  assert {
    condition     = contains(data.aws_iam_policy_document.data_dump.statement[1].actions, "kms:Encrypt")
    error_message = "Permission not found: kms:Encrypt"
  }

  assert {
    condition     = contains(data.aws_iam_policy_document.data_dump.statement[1].actions, "kms:ReEncrypt*")
    error_message = "Permission not found: kms:ReEncrypt*"
  }

  assert {
    condition     = contains(data.aws_iam_policy_document.data_dump.statement[1].actions, "kms:GenerateDataKey*")
    error_message = "Permission not found: kms:GenerateDataKey*"
  }

  assert {
    condition     = length(data.aws_iam_policy_document.data_dump.statement[1].actions) == 3
    error_message = "Should be 3 permissions on policy statement"
  }

  #  data.aws_iam_policy_document.data_dump.statement[1].resources cannot be tested on a 'plan'

  assert {
    condition     = aws_iam_role.data_dump.name == "test-env-test-db-dump-task"
    error_message = "Name should be test-env-test-db-dump-task"
  }

  assert {
    condition     = jsondecode(aws_iam_role.data_dump.assume_role_policy).Id == "assume_ecs_task_role"
    error_message = "Assume role policy id should be assume_ecs_task_role"
  }

  assert {
    condition = (
      aws_iam_role.data_dump.tags.application == "test-app" &&
      aws_iam_role.data_dump.tags.environment == "test-env" &&
      aws_iam_role.data_dump.tags.managed-by == "DBT Platform - Terraform" &&
      aws_iam_role.data_dump.tags.copilot-application == "test-app" &&
      aws_iam_role.data_dump.tags.copilot-environment == "test-env"
    )
    error_message = "Tags should be as expected"
  }

  assert {
    condition     = aws_iam_role_policy.allow_data_dump.name == "AllowDataDump"
    error_message = "Name should be 'AllowDataDump'"
  }

  assert {
    condition     = aws_iam_role_policy.allow_data_dump.role == "test-env-test-db-dump-task"
    error_message = "Role should be 'test-env-test-db-dump-task'"
  }

  #  aws_iam_role_policy.allow_data_dump.policy cannot be tested on a 'plan'

  assert {
    condition     = aws_ecs_task_definition.service.family == "test-env-test-db-dump"
    error_message = "Family should be 'test-env-test-db-dump'"
  }


  # resource "aws_ecs_task_definition" "service" {
  #   family = local.task_name
  #   container_definitions = jsonencode([
  #     {
  #       name      = local.task_name
  #       image     = "public.ecr.aws/uktrade/database-copy:latest"
  #       essential = true
  #       environment = [
  #         {
  #           name  = "DB_CONNECTION_STRING"
  #           value = "provided during task creation"
  #         },
  #         {
  #           name  = "DATA_COPY_OPERATION"
  #           value = "DUMP"
  #         },
  #         {
  #           name  = "S3_BUCKET_NAME"
  #           value = aws_s3_bucket.data_dump_bucket.bucket
  #         }
  #       ],
  #       portMappings = [
  #         {
  #           containerPort = 80
  #           hostPort      = 80
  #         }
  #       ]
  #       logConfiguration = {
  #         logDriver = "awslogs",
  #         options = {
  #           awslogs-group         = "/ecs/${local.task_name}"
  #           awslogs-region        = "eu-west-2"
  #           mode                  = "non-blocking"
  #           awslogs-create-group  = "true"
  #           max-buffer-size       = "25m"
  #           awslogs-stream-prefix = "ecs"
  #         }
  #       }


  #     }
  #   ])

  #   cpu    = 1024
  #   memory = 3072


  #   requires_compatibilities = ["FARGATE"]

  #   task_role_arn      = aws_iam_role.data_dump.arn
  #   execution_role_arn = aws_iam_role.data_dump_task_execution_role.arn
  #   network_mode       = "awsvpc"

  #   runtime_platform {
  #     cpu_architecture        = "ARM64"
  #     operating_system_family = "LINUX"
  #   }
  # }


  # resource "aws_s3_bucket" "data_dump_bucket" {
  #   # checkov:skip=CKV_AWS_144: Cross Region Replication not Required
  #   # checkov:skip=CKV2_AWS_62: Requires wider discussion around log/event ingestion before implementing. To be picked up on conclusion of DBTP-974
  #   # checkov:skip=CKV2_AWS_61: This bucket is used for ephemeral data transfer - we do not need lifecycle configuration
  #   # checkov:skip=CKV_AWS_21: This bucket is used for ephemeral data transfer - we do not want versioning
  #   # checkov:skip=CKV_AWS_18:  Requires wider discussion around log/event ingestion before implementing. To be picked up on conclusion of DBTP-974
  #   bucket = local.dump_bucket_name
  #   tags   = local.tags
  # }

  # data "aws_iam_policy_document" "data_dump_bucket_policy" {
  #   statement {
  #     principals {
  #       type        = "*"
  #       identifiers = ["*"]
  #     }

  #     actions = [
  #       "s3:*",
  #     ]

  #     effect = "Deny"

  #     condition {
  #       test     = "Bool"
  #       variable = "aws:SecureTransport"

  #       values = [
  #         "false",
  #       ]
  #     }

  #     resources = [
  #       aws_s3_bucket.data_dump_bucket.arn,
  #       "${aws_s3_bucket.data_dump_bucket.arn}/*",
  #     ]
  #   }
  # }

  # resource "aws_s3_bucket_policy" "data_dump_bucket_policy" {
  #   bucket = aws_s3_bucket.data_dump_bucket.id
  #   policy = data.aws_iam_policy_document.data_dump_bucket_policy.json
  # }

  # resource "aws_kms_key" "data_dump_kms_key" {
  #   # checkov:skip=CKV_AWS_7:We are not currently rotating the keys
  #   description = "KMS Key for S3 encryption"
  #   tags        = local.tags

  #   policy = jsonencode({
  #     Id = "key-default-1"
  #     Statement = [
  #       {
  #         "Sid" : "Enable IAM User Permissions",
  #         "Effect" : "Allow",
  #         "Principal" : {
  #           "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
  #         },
  #         "Action" : "kms:*",
  #         "Resource" : "*"
  #       }
  #     ]
  #     Version = "2012-10-17"
  #   })
  # }

  # resource "aws_kms_alias" "data_dump_kms_alias" {
  #   depends_on    = [aws_kms_key.data_dump_kms_key]
  #   name          = local.dump_kms_key_alias
  #   target_key_id = aws_kms_key.data_dump_kms_key.id
  # }

  # resource "aws_s3_bucket_server_side_encryption_configuration" "encryption-config" {
  #   # checkov:skip=CKV2_AWS_67:We are not currently rotating the keys
  #   bucket = aws_s3_bucket.data_dump_bucket.id

  #   rule {
  #     apply_server_side_encryption_by_default {
  #       kms_master_key_id = aws_kms_key.data_dump_kms_key.arn
  #       sse_algorithm     = "aws:kms"
  #     }
  #   }
  # }

  # resource "aws_s3_bucket_public_access_block" "public_access_block" {
  #   bucket                  = aws_s3_bucket.data_dump_bucket.id
  #   block_public_acls       = true
  #   block_public_policy     = true
  #   ignore_public_acls      = true
  #   restrict_public_buckets = true
  # }


}
