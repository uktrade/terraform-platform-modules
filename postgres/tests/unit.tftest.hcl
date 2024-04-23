override_data {
  target = data.aws_security_group.rds-endpoint
  values = {
    name = "sandbox-postgres-rds-endpoint-sg"
  }
}

override_data {
  target = data.aws_vpc.vpc
  values = {
    id         = "vpc-00112233aabbccdef"
    cidr_block = "10.0.0.0/16"
  }
}
override_data {
  target = data.aws_subnets.private-subnets
  values = {
    ids = ["subnet-000111222aaabbb01"]
  }
}

variables {
  application = "test-application"
  environment = "test-environment"
  name        = "test-name"
  vpc_name    = "sandbox-postgres"
  config = {
    version             = 14,
    deletion_protection = true,
    multi_az            = false,
  }
}


run "aws_security_group_unit_test" {
  command = plan

  assert {
    condition     = aws_security_group.default.name == "test-application-test-environment-test-name"
    error_message = "Invalid name for aws_security_group.default"
  }

  assert {
    condition     = aws_security_group.default.revoke_rules_on_delete == false
    error_message = "Should be: false."
  }

  assert {
    condition     = aws_security_group.default.tags.application == "test-application"
    error_message = "Invalid tags for aws_security_group.default application"
  }

  assert {
    condition     = aws_security_group.default.tags.environment == "test-environment"
    error_message = "Invalid tags for aws_security_group.default copilot-environment"
  }

  assert {
    condition     = aws_security_group.default.tags.copilot-application == "test-application"
    error_message = "Invalid tags for aws_security_group.default application"
  }

  assert {
    condition     = aws_security_group.default.tags.copilot-environment == "test-environment"
    error_message = "Invalid tags for aws_security_group.default copilot-environment"
  }

  assert {
    condition     = aws_security_group.default.tags.managed-by == "DBT Platform - Terraform"
    error_message = "Invalid tags for aws_security_group.default managed-by"
  }
}

run "aws_db_parameter_group_unit_test" {
  command = plan

  assert {
    condition     = aws_db_parameter_group.default.name == "test-application-test-environment-test-name-postgres14"
    error_message = "Invalid name for aws_db_parameter_group.default"
  }

  assert {
    condition     = aws_db_parameter_group.default.family == "postgres14"
    error_message = "Invalid family for aws_db_parameter_group.default"
  }

  assert {
    condition     = [for el in aws_db_parameter_group.default.parameter : el.value if el.name == "client_encoding"][0] == "utf8"
    error_message = "Invalid value for for aws_db_parameter_group.default client_encoding parameter"
  }

  assert {
    condition     = [for el in aws_db_parameter_group.default.parameter : el.value if el.name == "log_statement"][0] == "ddl"
    error_message = "Invalid value for for aws_db_parameter_group.default log_statement parameter"
  }

  assert {
    condition     = [for el in aws_db_parameter_group.default.parameter : el.value if el.name == "log_statement_sample_rate"][0] == "1.0"
    error_message = "Invalid value for for aws_db_parameter_group.default log_statement_sample_rate parameter"
  }
}


run "aws_db_subnet_group_unit_test" {
  command = plan

  assert {
    condition     = aws_db_subnet_group.default.name == "test-application-test-environment-test-name"
    error_message = "Invalid name for aws_db_subnet_group.default"
  }

  assert {
    condition     = length(aws_db_subnet_group.default.subnet_ids) == 1
    error_message = "Should be: 1"
  }
}

run "aws_kms_key_unit_test" {
  command = plan

  assert {
    condition     = aws_kms_key.default.description == "test-application-test-environment-test-name KMS key"
    error_message = "Invalid description for aws_kms_key.default"
  }

  assert {
    condition     = aws_kms_key.default.is_enabled == true
    error_message = "Should be: true"
  }

  assert {
    condition     = aws_kms_key.default.bypass_policy_lockout_safety_check == false
    error_message = "Should be: false"
  }

  assert {
    condition     = aws_kms_key.default.enable_key_rotation == false
    error_message = "Should be: false"
  }

  assert {
    condition     = aws_kms_key.default.key_usage == "ENCRYPT_DECRYPT"
    error_message = "Should be: ENCRYPT_DECRYPT"
  }

  assert {
    condition     = aws_kms_key.default.customer_master_key_spec == "SYMMETRIC_DEFAULT"
    error_message = "Should be: SYMMETRIC_DEFAULT"
  }
}

run "aws_db_instance_unit_test" {
  command = plan

  # Test aws_db_instance.default resource version
  assert {
    condition     = aws_db_instance.default.db_name == "main"
    error_message = "Invalid db_name for aws_db_instance.default"
  }

  assert {
    condition     = aws_db_instance.default.db_subnet_group_name == "test-application-test-environment-test-name"
    error_message = "Invalid db_subnet_group_name for aws_db_instance.default"
  }

  assert {
    condition     = aws_db_instance.default.engine == "postgres"
    error_message = "Should be: postgres"
  }

  assert {
    condition     = aws_db_instance.default.engine_version == "14"
    error_message = "Should be: 14"
  }

  assert {
    condition     = aws_db_instance.default.username == "postgres"
    error_message = "Should be: postgres"
  }

  # Test aws_db_instance.default resource storage
  assert {
    condition     = aws_db_instance.default.storage_encrypted == true
    error_message = "Should be: true"
  }

  assert {
    condition     = aws_db_instance.default.publicly_accessible == false
    error_message = "Should be: false"
  }

  assert {
    condition     = aws_db_instance.default.iam_database_authentication_enabled == false
    error_message = "Should be: false"
  }

  assert {
    condition     = aws_db_instance.default.multi_az == false
    error_message = "Should be: false"
  }

  assert {
    condition     = aws_db_instance.default.backup_retention_period == 7
    error_message = "Should be: 7"
  }

  assert {
    condition     = aws_db_instance.default.backup_window == "07:00-09:00"
    error_message = "Should be: 07:00-09:00"
  }

  assert {
    condition     = aws_db_instance.default.allocated_storage == 20
    error_message = "Should be: 20"
  }

  assert {
    condition     = aws_db_instance.default.manage_master_user_password == true
    error_message = "Should be: true"
  }

  assert {
    condition     = aws_db_instance.default.copy_tags_to_snapshot == true
    error_message = "Should be: true"
  }

  # Test aws_db_instance.default resource monitoring
  assert {
    condition     = aws_db_instance.default.performance_insights_enabled == true
    error_message = "Should be: true"
  }

  assert {
    condition     = aws_db_instance.default.performance_insights_retention_period == 7
    error_message = "Should be: 7"
  }

  assert {
    condition     = aws_db_instance.default.monitoring_interval == 15
    error_message = "Should be: 15"
  }

  # Test aws_db_instance.default resource upgrades
  assert {
    condition     = aws_db_instance.default.allow_major_version_upgrade == true
    error_message = "Should be: true"
  }

  assert {
    condition     = aws_db_instance.default.apply_immediately == false
    error_message = "Should be: false"
  }

  assert {
    condition     = aws_db_instance.default.auto_minor_version_upgrade == true
    error_message = "Should be: true"
  }

  assert {
    condition     = aws_db_instance.default.maintenance_window == "mon:00:00-mon:03:00"
    error_message = "Should be: mon:00:00-mon:03:00"
  }

}

run "aws_iam_role_unit_test" {
  command = plan

  # Test aws_iam_role.enhanced-monitoring resource
  assert {
    condition     = aws_iam_role.enhanced-monitoring.name_prefix == "rds-enhanced-monitoring-"
    error_message = "Invalid name_prefix for aws_iam_role.enhanced-monitoring"
  }

  assert {
    condition     = aws_iam_role.enhanced-monitoring.max_session_duration == 3600
    error_message = "Should be: 3600"
  }

  assert {
    condition     = jsondecode(aws_iam_role.enhanced-monitoring.assume_role_policy).Statement[0].Action == "sts:AssumeRole"
    error_message = "Should be: sts:AssumeRole"
  }

  assert {
    condition     = jsondecode(aws_iam_role.enhanced-monitoring.assume_role_policy).Statement[0].Effect == "Allow"
    error_message = "Should be: Allow"
  }

  assert {
    condition     = jsondecode(aws_iam_role.enhanced-monitoring.assume_role_policy).Statement[0].Principal.Service == "monitoring.rds.amazonaws.com"
    error_message = "Should be: monitoring.rds.amazonaws.com"
  }

  assert {
    condition     = jsondecode(aws_iam_role.enhanced-monitoring.assume_role_policy).Version == "2012-10-17"
    error_message = "Should be: 2012-10-17"
  }

  # Test aws_iam_role_policy_attachment.enhanced-monitoring resource
  assert {
    condition     = aws_iam_role_policy_attachment.enhanced-monitoring.policy_arn == "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
    error_message = "Invalid policy_arn for aws_iam_role_policy_attachment.enhanced-monitoring"
  }

  # Test aws_iam_role.lambda-execution-role resource
  assert {
    condition     = aws_iam_role.lambda-execution-role.name == "test-application-test-environment-test-name-lambda-role"
    error_message = "Invalid name for aws_iam_role.lambda-execution-role"
  }

  assert {
    condition     = aws_iam_role.lambda-execution-role.max_session_duration == 3600
    error_message = "Should be: 3600"
  }

  assert {
    condition     = jsondecode(aws_iam_role.lambda-execution-role.assume_role_policy).Statement[0].Action == "sts:AssumeRole"
    error_message = "Should be: sts:AssumeRole"
  }

  assert {
    condition     = jsondecode(aws_iam_role.lambda-execution-role.assume_role_policy).Statement[0].Effect == "Allow"
    error_message = "Should be: Allow"
  }

  assert {
    condition     = jsondecode(aws_iam_role.lambda-execution-role.assume_role_policy).Statement[0].Principal.Service == "lambda.amazonaws.com"
    error_message = "Should be: lambda.amazonaws.com"
  }

  assert {
    condition     = jsondecode(aws_iam_role.lambda-execution-role.assume_role_policy).Version == "2012-10-17"
    error_message = "Should be: 2012-10-17"
  }
}

run "aws_cloudwatch_log_rds_subscription_filter_unit_test" {
  command = plan

  assert {
    condition     = aws_cloudwatch_log_subscription_filter.rds.name == "/aws/rds/instance/test-application/test-environment/test-name/postgresql"
    error_message = "Invalid name for aws_cloudwatch_log_subscription_filter.rds"
  }

  assert {
    condition     = endswith(aws_cloudwatch_log_subscription_filter.rds.role_arn, ":role/CWLtoSubscriptionFilterRole") == true
    error_message = "Invalid role_arn for aws_cloudwatch_log_subscription_filter.rds"
  }

  assert {
    condition     = aws_cloudwatch_log_subscription_filter.rds.distribution == "ByLogStream"
    error_message = "Should be: ByLogStream"
  }
}

run "aws_lambda_function_unit_test" {
  command = plan

  assert {
    condition     = aws_lambda_function.lambda.filename == "./manage_users.zip"
    error_message = "Should be: ./manage_users.zip"
  }

  assert {
    condition     = aws_lambda_function.lambda.function_name == "test-application-test-environment-test-name-rds-create-user"
    error_message = "Should be: test-application-test-environment-test-name-rds-create-user"
  }

  assert {
    condition     = aws_lambda_function.lambda.handler == "manage_users.handler"
    error_message = "Should be: manage_users.handler"
  }

  assert {
    condition     = aws_lambda_function.lambda.runtime == "python3.11"
    error_message = "Should be: python3.11"
  }

  assert {
    condition     = aws_lambda_function.lambda.memory_size == 128
    error_message = "Should be: 128"
  }

  assert {
    condition     = aws_lambda_function.lambda.timeout == 10
    error_message = "Should be: 10"
  }

  assert {
    condition     = length(aws_lambda_function.lambda.layers) == 1
    error_message = "Should be: 1"
  }

  assert {
    condition     = endswith(aws_lambda_function.lambda.layers[0], ":layer:python-postgres:1") == true
    error_message = "Should be: end with layer:python-postgres:1"
  }

  assert {
    condition     = [for el in aws_lambda_function.lambda.vpc_config : true if el.ipv6_allowed_for_dual_stack == false][0] == true
    error_message = "Should be: false"
  }
}

run "aws_lambda_invocation_unit_test" {
  command = plan

  # Test aws_lambda_invocation.create-application-user resource
  assert {
    condition     = aws_lambda_invocation.create-application-user.function_name == "test-application-test-environment-test-name-rds-create-user"
    error_message = "Should be: test-application-test-environment-test-name-rds-create-user"
  }

  assert {
    condition     = aws_lambda_invocation.create-application-user.lifecycle_scope == "CREATE_ONLY"
    error_message = "Should be: CREATE_ONLY"
  }

  assert {
    condition     = aws_lambda_invocation.create-application-user.qualifier == "$LATEST"
    error_message = "Should be: $LATEST"
  }

  assert {
    condition     = aws_lambda_invocation.create-application-user.terraform_key == "tf"
    error_message = "Should be: tf"
  }

  # Test aws_lambda_invocation.create-readonly-user resource
  assert {
    condition     = aws_lambda_invocation.create-readonly-user.function_name == "test-application-test-environment-test-name-rds-create-user"
    error_message = "Should be: test-application-test-environment-test-name-rds-create-user"
  }

  assert {
    condition     = aws_lambda_invocation.create-readonly-user.lifecycle_scope == "CREATE_ONLY"
    error_message = "Should be: CREATE_ONLY"
  }

  assert {
    condition     = aws_lambda_invocation.create-readonly-user.qualifier == "$LATEST"
    error_message = "Should be: $LATEST"
  }

  assert {
    condition     = aws_lambda_invocation.create-readonly-user.terraform_key == "tf"
    error_message = "Should be: tf"
  }
}

run "aws_ssm_parameter_master_secret_arn_unit_test" {
  command = plan

  assert {
    condition     = aws_ssm_parameter.master-secret-arn.name == "/copilot/test-application/test-environment/secrets/TEST_NAME_RDS_MASTER_ARN"
    error_message = "Should be: /copilot/test-application/test-environment/secrets/TEST_NAME_RDS_MASTER_ARN"
  }

  assert {
    condition     = aws_ssm_parameter.master-secret-arn.type == "SecureString"
    error_message = "Should be: SecureString"
  }
}
