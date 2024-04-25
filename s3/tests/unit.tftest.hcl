variables {
  vpc_name    = "s3-test-vpc-name"
  application = "s3-test-application"
  environment = "s3-test-environment"
  name        = "s3-test-name"
  config = {
    "bucket_name" = "dbt-terraform-test-s3-module",
    "type"        = "string",
    "versioning"  = false,
    "objects"     = [],
  }
}

run "aws_s3_bucket_unit_test" {
  command = plan

  assert {
    condition     = aws_s3_bucket.this.bucket == "dbt-terraform-test-s3-module-test"
    error_message = "Invalid name for aws_s3_bucket"
  }

  assert {
    condition     = aws_s3_bucket.this.force_destroy == false
    error_message = "Invalid value for aws_s3_bucket force_destroy parameter, should be false."
  }

  assert {
    condition     = aws_s3_bucket.this.tags["environment"] == "s3-test-environment"
    error_message = "Invalid value for aws_s3_bucket tags parameter."
  }

  assert {
    condition     = aws_s3_bucket.this.tags["application"] == "s3-test-application"
    error_message = "Invalid value for aws_s3_bucket tags parameter."
  }

  assert {
    condition     = aws_s3_bucket.this.tags["copilot-application"] == "s3-test-application"
    error_message = "Invalid value for aws_s3_bucket tags parameter."
  }

  assert {
    condition     = aws_s3_bucket.this.tags["copilot-environment"] == "s3-test-environment"
    error_message = "Invalid value for aws_s3_bucket tags parameter."
  }

  assert {
    condition     = aws_s3_bucket.this.tags["managed-by"] == "DBT Platform - Terraform"
    error_message = "Invalid value for aws_s3_bucket tags parameter."
  }
}

run "aws_iam_policy_document_unit_test" {
  command = plan

  assert {
    condition     = [for el in data.aws_iam_policy_document.bucket-policy.statement[0].condition : true if el.variable == "aws:SecureTransport"][0] == true
    error_message = "Invalid value for aws_iam_policy_document bucket_policy.statement.condition.variable, should be aws:SecureTransport"
  }

  assert {
    condition     = data.aws_iam_policy_document.bucket-policy.statement[0].effect == "Deny"
    error_message = "Invalid value for aws_iam_policy_document bucket_policy.statement.effect, should be Deny"
  }

  assert {
    condition     = [for el in data.aws_iam_policy_document.bucket-policy.statement[0].actions : true if el == "s3:*"][0] == true
    error_message = "Invalid value for aws_iam_policy_document bucket_policy.statement.actions, should be s3:*"
  }
}

run "aws_s3_bucket_versioning_unit_test" {
  command = plan

  assert {
    condition     = aws_s3_bucket_versioning.this-versioning.versioning_configuration[0].status == "Disabled"
    error_message = "Invalid value for aws_s3_bucket_versioning versioning_configuration parameter, should be Disabled"
  }
}

run "aws_kms_key_unit_test" {
  command = plan

  assert {
    condition     = aws_kms_key.kms-key.bypass_policy_lockout_safety_check == false
    error_message = "Invalid value for aws_kms_key bypass_policy_lockout_safety_check parameter, should be false"
  }

  assert {
    condition     = aws_kms_key.kms-key.customer_master_key_spec == "SYMMETRIC_DEFAULT"
    error_message = "Invalid value for aws_kms_key customer_master_key_spec parameter, should be SYMMETRIC_DEFAULT"
  }

  assert {
    condition     = aws_kms_key.kms-key.enable_key_rotation == false
    error_message = "Invalid value for aws_kms_key enable_key_rotation parameter, should be false"
  }

  assert {
    condition     = aws_kms_key.kms-key.is_enabled == true
    error_message = "Invalid value for aws_kms_key is_enabled parameter, should be true"
  }

  assert {
    condition     = aws_kms_key.kms-key.key_usage == "ENCRYPT_DECRYPT"
    error_message = "Invalid value for aws_kms_key key_usage parameter, should be ENCRYPT_DECRYPT"
  }

  assert {
    condition     = aws_kms_key.kms-key.tags["application"] == "s3-test-application"
    error_message = "Invalid value for aws_kms_key tags parameter."
  }

  assert {
    condition     = aws_kms_key.kms-key.tags["environment"] == "s3-test-environment"
    error_message = "Invalid value for aws_kms_key tags parameter."
  }
}

run "aws_kms_alias_unit_test" {
  command = plan

  assert {
    condition     = aws_kms_alias.s3-bucket.name == "alias/dbt-terraform-test-s3-module-key"
    error_message = "Invalid value for aws_kms_alias.s3-bucket name parameter, should be alias/dbt-terraform-test-s3-module-key"
  }
}

run "aws_s3_bucket_server_side_encryption_configuration_unit_test" {
  command = plan

  assert {
    condition     = [for el in aws_s3_bucket_server_side_encryption_configuration.encryption-config.rule : true if[for el2 in el.apply_server_side_encryption_by_default : true if el2.sse_algorithm == "aws:kms"][0] == true][0] == true
    error_message = "Invalid value for aws_s3_bucket_server_side_encryption_configuration tags parameter."
  }
}

run "aws_s3_bucket_versioning_enabled_unit_test" {
  command = plan

  variables {
    config = {
      "bucket_name" = "dbt-terraform-test-s3-module",
      "type"        = "string",
      "versioning"  = true,
      "objects"     = [],
    }
  }

  ### Test aws_s3_bucket_versioning resource ###
  assert {
    condition     = aws_s3_bucket_versioning.this-versioning.versioning_configuration[0].status == "Enabled"
    error_message = "Invalid value for aws_s3_bucket_versioning versioning_configuration.status, should be Enabled"
  }
}

run "aws_s3_bucket_object_lock_configuration_governance_unit_test" {
  command = plan

  variables {
    config = {
      "bucket_name"      = "dbt-terraform-test-s3-module",
      "type"             = "string",
      "versioning"       = true,
      "retention_policy" = { "mode" = "GOVERNANCE", "days" = 1 },
      "objects"          = [],
    }
  }

  assert {
    condition     = [for el in aws_s3_bucket_object_lock_configuration.object-lock-config[0].rule : true if el.default_retention[0].mode == "GOVERNANCE"][0] == true
    error_message = "Invalid value for aws_s3_bucket_object_lock_configuration default_retention.mode parameter, should be GOVERNANCE"
  }

  assert {
    condition     = [for el in aws_s3_bucket_object_lock_configuration.object-lock-config[0].rule : true if el.default_retention[0].days == 1][0] == true
    error_message = "Invalid value for aws_s3_bucket_object_lock_configuration default_retention.days parameter, should be 1"
  }
}

run "aws_s3_bucket_object_lock_configuration_compliance_unit_test" {
  command = plan

  variables {
    config = {
      "bucket_name"      = "dbt-terraform-test-s3-module",
      "type"             = "string",
      "versioning"       = true,
      "retention_policy" = { "mode" = "COMPLIANCE", "years" = 1 },
      "objects"          = [],
    }
  }

  assert {
    condition     = [for el in aws_s3_bucket_object_lock_configuration.object-lock-config[0].rule : true if el.default_retention[0].mode == "COMPLIANCE"][0] == true
    error_message = "Invalid s3 bucket object lock configuration"
  }

  assert {
    condition     = [for el in aws_s3_bucket_object_lock_configuration.object-lock-config1[0].rule : true if el.default_retention[0].years == 1][0] == true
    error_message = "Invalid s3 bucket object lock configuration"
  }
}

run "aws_s3_bucket_object_lock_configuration_nopolicy_unit_test" {
  command = plan

  variables {
    config = {
      "bucket_name" = "dbt-terraform-test-s3-module",
      "type"        = "string",
      "versioning"  = true,
      "objects"     = [],
    }
  }

  ### Test aws_s3_bucket_object_lock_configuration resource ###
  assert {
    condition     = aws_s3_bucket_object_lock_configuration.object-lock-config == []
    error_message = "Invalid s3 bucket object lock configuration"
  }
}
