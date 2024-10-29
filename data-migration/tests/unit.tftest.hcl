mock_provider "aws" {}

variables {
  config = {
    "source_bucket_arn"  = "test-source-bucket-arn"
    "source_kms_key_arn" = "test-source-kms-key-arn"
    "worker_role_arn"    = "test-role-arn"
  }
  destination_bucket_arn        = "test-destination-bucket-arn"
  destination_bucket_identifier = "test-destination-bucket-name"
}

override_data {
  target = data.aws_iam_policy_document.allow_assume_role
  values = {
    json = "{\"Sid\": \"AllowAssumeWorkerRole\"}"
  }
}

override_data {
  target = data.aws_iam_policy_document.s3_migration_policy_document
  values = {
    json = "{\"Sid\": \"AllowReadOnSourceBucket\"}"
  }
}

run "data_migration_unit_test" {
  command = plan

  assert {
    condition     = aws_iam_role.s3_migration_role.name == "test-destination-bucket-name-S3MigrationRole"
    error_message = "Should be: test-destination-bucket-name-S3MigrationRole"
  }

  # Check that the correct aws_iam_policy_document is used from the mocked data json
  assert {
    condition     = aws_iam_role.s3_migration_role.assume_role_policy == "{\"Sid\": \"AllowAssumeWorkerRole\"}"
    error_message = "Should be: {\"Sid\": \"AllowAssumeWorkerRole\"}"
  }

  assert {
    condition     = aws_iam_role_policy.s3_migration_policy.name == "test-destination-bucket-name-S3MigrationPolicy"
    error_message = "Should be: test-destination-bucket-name-S3MigrationPolicy"
  }

  assert {
    condition     = aws_iam_role_policy.s3_migration_policy.role == "test-destination-bucket-name-S3MigrationRole"
    error_message = "Should be: test-destination-bucket-name-S3MigrationRole"
  }

  # Check that the correct aws_iam_policy_document is used from the mocked data json
  assert {
    condition     = aws_iam_role_policy.s3_migration_policy.policy == "{\"Sid\": \"AllowReadOnSourceBucket\"}"
    error_message = "Should be: {\"Sid\": \"AllowReadOnSourceBucket\"}"
  }

  # Check the contents of the policy document
  assert {
    condition     = strcontains(jsonencode(data.aws_iam_policy_document.s3_migration_policy_document.statement[1].resources), "test-destination-bucket-arn")
    error_message = "Should contain: test-destination-bucket-arn"
  }
  assert {
    condition     = strcontains(jsonencode(data.aws_iam_policy_document.s3_migration_policy_document.statement[3].actions), "kms:Decrypt") == true
    error_message = "Statement should contain kms:Decrypt"
  }
}

run "data_migration_without_source_kms_key" {
  command = plan

  variables {
    config = {
      "source_bucket_arn" = "test-source-bucket-arn"
      "worker_role_arn"   = "test-role-arn"
    }
    destination_bucket_arn        = "test-destination-bucket-arn"
    destination_bucket_identifier = "test-destination-bucket-name"
  }

  assert {
    # Cannot check the specific statement, because it does not exist
    condition     = strcontains(jsonencode(data.aws_iam_policy_document.s3_migration_policy_document), "kms:Decrypt") == false
    error_message = "Statement should not contain kms:Decrypt"
  }
}
