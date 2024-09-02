variables {
  application = "iam-test-application"
  environment = "iam-test-environment"
  config = {
    "source_bucket_arn"         = "test-source-bucket-arn"
    "source_kms_key_arn"        = "test-kms-key-arn"
    "migration_worker_role_arn" = "test-role-arn"
  }
  destination_bucket_arn        = "test-bucket-arn"
  destination_bucket_identifier = "test-bucket-name"
}


run "aws_iam_unit_test" {
  command = plan

  assert {
    condition     = aws_iam_role.s3_data_migration_role.name == "test-bucket-name-S3DataMigration"
    error_message = "Should be: test-bucket-name-S3DataMigration"
  }

  assert {
    condition     = aws_iam_role.s3_data_migration_role.assume_role_policy != null
    error_message = "Role should have an assume role policy"
  }

  assert {
    condition     = aws_iam_role_policy.s3_external_import_policy.name == "test-bucket-name-ExternalImport"
    error_message = "Should be: test-bucket-name-ExternalImport"
  }

  assert {
    condition     = aws_iam_role_policy.s3_external_import_policy.role == "test-bucket-name-S3DataMigration"
    error_message = "Should be: test-bucket-name-S3DataMigration"
  }

  assert {
    condition     = can(regex("test-bucket-arn", aws_iam_role_policy.s3_external_import_policy.policy))
    error_message = "Statement should contain resource arn: test-bucket-arn"
  }
}