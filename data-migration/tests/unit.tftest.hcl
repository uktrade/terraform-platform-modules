variables {
  config = {
    "source_bucket_arn"  = "test-source-bucket-arn"
    "source_kms_key_arn" = "test-source-kms-key-arn"
    "worker_role_arn"    = "test-role-arn"
  }
  destination_bucket_arn        = "test-destination-bucket-arn"
  destination_bucket_identifier = "test-destination-bucket-name"
}


run "data_migration_unit_test" {
  command = plan

  assert {
    condition     = aws_iam_role.s3_migration_role.name == "test-bucket-name-S3MigrationRole"
    error_message = "Should be: test-bucket-name-S3MigrationRole"
  }

  assert {
    condition     = aws_iam_role.s3_migration_role.assume_role_policy != null
    error_message = "Role should have an assume role policy"
  }

  assert {
    condition     = aws_iam_role_policy.s3_migration_policy.name == "test-bucket-name-S3MigrationPolicy"
    error_message = "Should be: test-bucket-name-S3MigrationPolicy"
  }

  assert {
    condition     = aws_iam_role_policy.s3_migration_policy.role == "test-bucket-name-S3MigrationRole"
    error_message = "Should be: test-bucket-name-S3MigrationRole"
  }

  assert {
    condition     = strcontains(aws_iam_role_policy.s3_migration_policy.policy, "test-bucket-arn")
    error_message = "Statement should contain resource arn: test-bucket-arn"
  }

  assert {
    condition     = strcontains(aws_iam_role_policy.s3_migration_policy.policy, "kms:Decrypt")
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
    destination_bucket_arn        = "test-bucket-arn"
    destination_bucket_identifier = "test-bucket-name"
  }

  assert {
    condition     = strcontains(aws_iam_role_policy.s3_migration_policy.policy, "kms:Decrypt") == false
    error_message = "Statement should not contain kms:Decrypt"
  }
}