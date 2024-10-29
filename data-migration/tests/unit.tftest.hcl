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

  # We can check that the correct data is set for the assume_role_policy, but cannot check the full details on a plan
  assert {
    condition     = aws_iam_role.s3_migration_role.assume_role_policy == "{\"Sid\": \"AllowAssumeWorkerRole\"}"
    error_message = "Should be: {\"Sid\": \"AllowAssumeWorkerRole\"}"
  }

  assert {
    condition     = aws_iam_role.s3_migration_role.assume_role_policy != null
    error_message = "Role should have an assume role policy"
  }

  assert {
    condition     = aws_iam_role_policy.s3_migration_policy.name == "test-destination-bucket-name-S3MigrationPolicy"
    error_message = "Should be: test-destination-bucket-name-S3MigrationPolicy"
  }

  assert {
    condition     = aws_iam_role_policy.s3_migration_policy.role == "test-destination-bucket-name-S3MigrationRole"
    error_message = "Should be: test-destination-bucket-name-S3MigrationRole"
  }

  # We can check that the correct data is set for the policy, but cannot check the full details on a plan
  assert {
    condition     = aws_iam_role_policy.s3_migration_policy.policy == "{\"Sid\": \"AllowReadOnSourceBucket\"}"
    error_message = "Should be: {\"Sid\": \"AllowReadOnSourceBucket\"}"
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

  # Cannot test for the absence of this on a plan
  # strcontains(aws_iam_role_policy.s3_migration_policy.policy, "kms:Decrypt") == false
}
