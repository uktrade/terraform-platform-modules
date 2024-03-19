run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

run "e2e_test" {

  command = apply

  variables {
    vpc_name    = "s3-test-name"
    application = "s3-test-application"
    environment = "s3-test-environment"
    config = {
      "params" = { "bucket_name" = "${run.setup_tests.bucket_prefix}-terraform-test-module-s3" }
    }
  }

  ### Test aws_kms_alias resource ###
  assert {
    condition     = aws_kms_alias.s3-bucket.id == "alias/s3-test-application-s3-test-applicationS3Bucket-key"
    error_message = "Invalid s3 KMS alias name value"
  }

  assert {
    condition     = aws_kms_alias.s3-bucket.arn == "arn:aws:kms:eu-west-2:852676506468:alias/s3-test-application-s3-test-applicationS3Bucket-key"
    error_message = "Invalid s3 KMS alias arn value"
  }

  ### Test aws_kms_key resource ###
  assert {
    condition     = startswith(aws_kms_key.s3-bucket.arn, "arn:aws:kms:eu-west-2:852676506468") == true
    error_message = "Invalid s3 KMS key tags"
  }

  ### Test aws_kms_key tags ###
  assert {
    condition     = aws_kms_key.s3-bucket.tags["Application"] == "s3-test-application"
    error_message = "Invalid s3 KMS key tags"
  }

  assert {
    condition     = aws_kms_key.s3-bucket.tags["Environment"] == "s3-test-environment"
    error_message = "Invalid s3 KMS key tags"
  }

  # ### Test resources created by 'this' module ###
  assert {
    condition     = endswith(module.this.s3_bucket_id, "-terraform-test-module-s3") == true
    error_message = "Invalid S3 bucket policy"
  }

  assert {
    condition     = jsondecode(module.this.s3_bucket_policy).Statement[0].Condition.Bool["aws:SecureTransport"] == "false"
    error_message = "Invalid S3 bucket policy"
  }

  assert {
    condition     = module.this.s3_bucket_region == "eu-west-2"
    error_message = "Invalid S3 bucket policy"
  }

}

