variables {
  application   = "test-app"
  environment   = "test-env"
  database_name = "test-db"
  task = {
    from = "some-other-env"
    to   = "test-env"
  }
}

override_data {
  target = data.aws_s3_bucket.data_dump_bucket
  values = {
    bucket = "mock-dump-bucket"
    arn    = "arn://mock-dump-bucket"
  }
}

override_data {
  target = data.aws_kms_key.data_dump_kms_key
  values = {
    arn = "arn://mock-dump-bucket-kms-key"
  }
}

run "data_restore_unit_test" {
  command = plan

  assert {
    condition     = local.dump_kms_key_alias == "alias/some-other-env-test-db-dump"
    error_message = "Dump Kms key alias should be: alias/some-other-env-test-db-dump"
  }

  assert {
    condition     = local.dump_bucket_name == "some-other-env-test-db-dump"
    error_message = "Dump bucket name should be: alias/some-other-env-te"
  }

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
    condition     = aws_iam_role.data_restore_task_execution_role.name == "test-env-test-db-restore-exec"
    error_message = "Task execution role name should be: 'test-env-test-db-restore-exec'"
  }

  assert {
    condition     = jsondecode(aws_iam_role.data_restore_task_execution_role.assume_role_policy).Statement[0].Sid == "AllowECSAssumeRole"
    error_message = "Statement Sid should be: 'AllowECSAssumeRole'"
  }

  assert {
    condition     = aws_iam_role_policy.allow_task_creation.name == "AllowTaskCreation"
    error_message = "Role policy name should be: 'AllowTaskCreation'"
  }

  assert {
    condition     = aws_iam_role_policy.allow_task_creation.role == "test-env-test-db-restore-exec"
    error_message = "Role name should be: 'test-env-test-db-restore-exec'"
  }

  assert {
    condition     = data.aws_iam_policy_document.data_restore.statement[0].sid == "AllowReadFromS3"
    error_message = "Should be 'AllowReadFromS3'"
  }

  assert {
    condition     = length(data.aws_iam_policy_document.data_restore.statement) == 2
    error_message = "Should be 1 policy statement"
  }

  assert {
    condition     = contains(data.aws_iam_policy_document.data_restore.statement[0].actions, "s3:ListBucket")
    error_message = "Permission not found: s3:ListBucket"
  }

  assert {
    condition     = contains(data.aws_iam_policy_document.data_restore.statement[0].actions, "s3:GetObject")
    error_message = "Permission not found: s3:GetObject"
  }

  assert {
    condition     = contains(data.aws_iam_policy_document.data_restore.statement[0].actions, "s3:GetObjectTagging")
    error_message = "Permission not found: s3:GetObjectTagging"
  }

  assert {
    condition     = contains(data.aws_iam_policy_document.data_restore.statement[0].actions, "s3:GetObjectVersion")
    error_message = "Permission not found: s3:GetObjectVersion"
  }

  assert {
    condition     = contains(data.aws_iam_policy_document.data_restore.statement[0].actions, "s3:GetObjectVersionTagging")
    error_message = "Permission not found: s3:GetObjectVersionTagging"
  }

  assert {
    condition     = length(data.aws_iam_policy_document.data_restore.statement[0].actions) == 5
    error_message = "Should be 7 permissions on policy statement"
  }

  #  data.aws_iam_policy_document.data_restore.statement[0].resources cannot be tested on a 'plan'

  assert {
    condition     = contains(data.aws_iam_policy_document.data_restore.statement[1].actions, "kms:Decrypt")
    error_message = "Permission not found: kms:Decrypt"
  }

  assert {
    condition     = length(data.aws_iam_policy_document.data_restore.statement[1].actions) == 1
    error_message = "Should be 1 permissions on policy statement"
  }

  # data.aws_iam_policy_document.data_restore.statement[1].resources cannot be tested on a 'plan'

  assert {
    condition     = aws_iam_role.data_restore.name == "test-env-test-db-restore-task"
    error_message = "Name should be test-env-test-db-restore-task"
  }

  assert {
    condition     = jsondecode(aws_iam_role.data_restore.assume_role_policy).Id == "assume_ecs_task_role"
    error_message = "Assume role policy id should be assume_ecs_task_role"
  }

  assert {
    condition = (
      aws_iam_role.data_restore.tags.application == "test-app" &&
      aws_iam_role.data_restore.tags.environment == "test-env" &&
      aws_iam_role.data_restore.tags.managed-by == "DBT Platform - Terraform" &&
      aws_iam_role.data_restore.tags.copilot-application == "test-app" &&
      aws_iam_role.data_restore.tags.copilot-environment == "test-env"
    )
    error_message = "Tags should be as expected"
  }

  assert {
    condition     = aws_iam_role_policy.allow_data_restore.name == "AllowDataRestore"
    error_message = "Name should be 'AllowDataRestore'"
  }

  assert {
    condition     = aws_iam_role_policy.allow_data_restore.role == "test-env-test-db-restore-task"
    error_message = "Role should be 'test-env-test-db-restore-task'"
  }

  #  aws_iam_role_policy.allow_data_restore.policy cannot be tested on a 'plan'

  assert {
    condition     = aws_ecs_task_definition.service.family == "test-env-test-db-restore"
    error_message = "Family should be 'test-env-test-db-restore'"
  }

  assert {
    condition     = aws_ecs_task_definition.service.cpu == "1024"
    error_message = "CPU should be '1024'"
  }

  assert {
    condition     = aws_ecs_task_definition.service.memory == "3072"
    error_message = "CPU should be '3072'"
  }

  assert {
    condition = (
      length(aws_ecs_task_definition.service.requires_compatibilities) == 1 &&
      contains(aws_ecs_task_definition.service.requires_compatibilities, "FARGATE")
    )
    error_message = "Requires compatibilities should be ['FARGATE']"
  }

  # task_role_arn cannot be tested using plan
  # execution_role_arn cannot be tested using plan

  assert {
    condition     = aws_ecs_task_definition.service.network_mode == "awsvpc"
    error_message = "Network modes should be awsvpc"
  }

  assert {
    condition     = aws_ecs_task_definition.service.runtime_platform[0].cpu_architecture == "ARM64"
    error_message = "CPU Arch should be ARM64"
  }

  assert {
    condition     = aws_ecs_task_definition.service.runtime_platform[0].operating_system_family == "LINUX"
    error_message = "OS family should be LINUX"
  }

}
