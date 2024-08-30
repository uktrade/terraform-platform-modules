variables {
  application = "iam-test-application"
  environment = "iam-test-environment"
  config = {
    "source_bucket_arn"  = "test-source-bucket-arn"
    "source_kms_key_arn" = "test-kms-key-arn"
    "importing_role_arn" = "test-role-arn"
  }
  bucket_arn  = "test-bucket-arn"
  bucket_name = "test-bucket-name"
}


run "aws_iam_unit_test" {
  command = plan

  assert {
    condition     = aws_iam_role.external_service_access_role.name == "test-bucket-name-ExternalImport"
    error_message = "Should be: test-bucket-name-ExternalImport"
  }

  assert {
    condition     = aws_iam_role.external_service_access_role.assume_role_policy != null
    error_message = "Role should have an assume role policy"
  }

  assert {
    condition     = aws_iam_role_policy.s3_external_import_policy.name == "iam-test-application-iam-test-environment-allow-s3-external-import-actions"
    error_message = "Should be: iam-test-application-iam-test-environment-allow-s3-external-import-actions"
  }

  assert {
    condition     = aws_iam_role_policy.s3_external_import_policy.role == "test-bucket-name-ExternalImport"
    error_message = "Should be: test-bucket-name-ExternalImport"
  }

  assert {
    condition     = can(regex("test-bucket-arn", aws_iam_role_policy.s3_external_import_policy.policy))
    error_message = "Statement should contain resource arn: test-bucket-arn"
  }
}