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

mock_provider "aws" {
  alias = "domain-cdn"
}

mock_provider "aws" {
  alias = "domain"
}

run "aws_s3_bucket_unit_test" {
  command = plan

  assert {
    condition     = output.bucket_name == "dbt-terraform-test-s3-module"
    error_message = "Should be: dbt-terraform-test-s3-module"
  }

  assert {
    condition     = aws_s3_bucket.this.bucket == "dbt-terraform-test-s3-module"
    error_message = "Invalid name for aws_s3_bucket"
  }

  assert {
    condition     = aws_s3_bucket.this.force_destroy == false
    error_message = "Should be: false."
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

  assert {
    condition     = aws_s3_bucket_lifecycle_configuration.lifecycle-configuration == []
    error_message = "Should be: []"
  }

}

run "aws_iam_policy_document_unit_test" {
  command = plan

  assert {
    condition     = [for el in data.aws_iam_policy_document.bucket-policy.statement[0].condition : true if el.variable == "aws:SecureTransport"][0] == true
    error_message = "Should be: aws:SecureTransport"
  }

  assert {
    condition     = data.aws_iam_policy_document.bucket-policy.statement[0].effect == "Deny"
    error_message = "Should be: Deny"
  }

  assert {
    condition     = [for el in data.aws_iam_policy_document.bucket-policy.statement[0].actions : true if el == "s3:*"][0] == true
    error_message = "Should be: s3:*"
  }
}

run "aws_s3_bucket_versioning_unit_test" {
  command = plan

  assert {
    condition     = aws_s3_bucket_versioning.this-versioning.versioning_configuration[0].status == "Disabled"
    error_message = "Should be: Disabled"
  }
}

run "aws_kms_key_unit_test" {
  command = plan

  assert {
    condition     = aws_kms_key.kms-key.bypass_policy_lockout_safety_check == false
    error_message = "Should be: false"
  }

  assert {
    condition     = aws_kms_key.kms-key.customer_master_key_spec == "SYMMETRIC_DEFAULT"
    error_message = "Should be: SYMMETRIC_DEFAULT"
  }

  assert {
    condition     = aws_kms_key.kms-key.enable_key_rotation == false
    error_message = "Should be: false"
  }

  assert {
    condition     = aws_kms_key.kms-key.is_enabled == true
    error_message = "Should be: true"
  }

  assert {
    condition     = aws_kms_key.kms-key.key_usage == "ENCRYPT_DECRYPT"
    error_message = "Should be: ENCRYPT_DECRYPT"
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
    condition     = aws_kms_alias.s3-bucket.name == "alias/s3-test-application-s3-test-environment-dbt-terraform-test-s3-module-key"
    error_message = "Should be: alias/s3-test-application-s3-test-environment-dbt-terraform-test-s3-module-key"
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
    error_message = "Should be: Enabled"
  }
}

run "aws_s3_bucket_lifecycle_configuration_unit_test" {
  command = plan

  variables {
    config = {
      "bucket_name"     = "dbt-terraform-test-s3-module",
      "type"            = "string",
      "lifecycle_rules" = [{ "filter_prefix" = "/foo", "expiration_days" = 90, "enabled" = true }],
      "objects"         = [],
    }
  }

  ### Test aws_s3_bucket_lifecycle_configuration resource ###
  assert {
    condition     = aws_s3_bucket_lifecycle_configuration.lifecycle-configuration[0].rule[0].filter[0].prefix == "/foo"
    error_message = "Should be: /foo"
  }

  assert {
    condition     = aws_s3_bucket_lifecycle_configuration.lifecycle-configuration[0].rule[0].expiration[0].days == 90
    error_message = "Should be: 90"
  }

  assert {
    condition     = aws_s3_bucket_lifecycle_configuration.lifecycle-configuration[0].rule[0].abort_incomplete_multipart_upload[0].days_after_initiation == 7
    error_message = "Should be: 7"
  }

  assert {
    condition     = aws_s3_bucket_lifecycle_configuration.lifecycle-configuration[0].rule[0].status == "Enabled"
    error_message = "Should be: Enabled"
  }
}

run "aws_s3_bucket_lifecycle_configuration_no_prefix_unit_test" {
  command = plan

  variables {
    config = {
      "bucket_name"     = "dbt-terraform-test-s3-module",
      "type"            = "string",
      "lifecycle_rules" = [{ "expiration_days" = 90, "enabled" = true }],
      "objects"         = [],
    }
  }

  ### Test aws_s3_bucket_lifecycle_configuration resource when no prefix is used ###
  assert {
    condition     = aws_s3_bucket_lifecycle_configuration.lifecycle-configuration[0].rule[0].filter[0] != null
    error_message = "Should be: {}"
  }

  assert {
    condition     = aws_s3_bucket_lifecycle_configuration.lifecycle-configuration[0].rule[0].filter[0].prefix == null
    error_message = "Should be: null"
  }
}

run "aws_s3_bucket_data_migration_unit_test" {
  command = plan

  variables {
    config = {
      "bucket_name" = "dbt-terraform-test-s3-cross-account",
      "type"        = "s3",
      "data_migration" = {
        "import" = {
          "worker_role_arn"    = "arn:aws:iam::1234:role/service-role/my-privileged-arn",
          "source_kms_key_arn" = "arn:aws:iam::1234:my-external-kms-key-arn",
          "source_bucket_arn"  = "arn:aws:s3::1234:my-source-bucket"
        }
      }
    }
  }

  assert {
    condition     = module.data_migration[0].module_exists
    error_message = "data migration module should be created"
  }
}

run "aws_s3_bucket_not_data_migration_unit_test" {
  command = plan

  variables {
    config = {
      "bucket_name" = "dbt-terraform-test-s3-not-x-account",
      "type"        = "s3",
    }
  }

  assert {
    condition     = length(module.data_migration) == 0
    error_message = "data migration module should not be created"
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
    error_message = "Should be: GOVERNANCE"
  }

  assert {
    condition     = [for el in aws_s3_bucket_object_lock_configuration.object-lock-config[0].rule : true if el.default_retention[0].days == 1][0] == true
    error_message = "Should be: 1"
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
    condition     = [for el in aws_s3_bucket_object_lock_configuration.object-lock-config[0].rule : true if el.default_retention[0].years == 1][0] == true
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
