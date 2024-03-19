run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

variables {
  vpc_name    = "s3-test-vpc-name"
  application = "s3-test-application"
  environment = "s3-test-environment"
  name        = "s3-test-name"
  config = {
    "type"       = "string",
    "versioning" = false,
    "objects"    = [],
  }
}

run "e2e_test" {

  variables {
    config = {
      "bucket_name" = "${run.setup_tests.bucket_prefix}-terraform-test-module-s3",
      "type"        = "string",
      "versioning"  = false,
      "objects"     = [],
    }
  }

  command = apply

  ### Test aws_s3_bucket resource ###
  assert {
    condition     = endswith(aws_s3_bucket.this.bucket, "-terraform-test-module-s3") == true
    error_message = "Invalid S3 bucket name"
  }

  assert {
    condition     = aws_s3_bucket.this.tags["Environment"] == "s3-test-environment"
    error_message = "Invalid s3 bucket tags"
  }

  assert {
    condition     = aws_s3_bucket.this.tags["Application"] == "s3-test-application"
    error_message = "Invalid s3 bucket tags"
  }

  ### Test aws_iam_policy_document ###
  assert {
    condition     = [for el in data.aws_iam_policy_document.bucket-policy.statement[0].condition : true if el.variable == "aws:SecureTransport"][0] == true
    error_message = "Invalid s3 KMS key tags"
  }

  ### Test aws_kms_key resource ###
  assert {
    condition     = startswith(aws_kms_key.kms-key.arn, "arn:aws:kms:eu-west-2:852676506468") == true
    error_message = "Invalid s3 KMS key arn value"
  }

  ### Test aws_s3_bucket_versioning resource ###
  assert {
    condition     = aws_s3_bucket_versioning.this-versioning.versioning_configuration[0].status == "Disabled"
    error_message = "Invalid s3 bucket versioning status"
  }

  ### Test aws_kms_key tags ###
  assert {
    condition     = aws_kms_key.kms-key.tags["Application"] == "s3-test-application"
    error_message = "Invalid s3 KMS key tags"
  }

  assert {
    condition     = aws_kms_key.kms-key.tags["Environment"] == "s3-test-environment"
    error_message = "Invalid s3 KMS key tags"
  }

  ### Test aws_s3_bucket_server_side_encryption_configuration resource sse_algorithm ###
  assert {
    condition     = [for el in aws_s3_bucket_server_side_encryption_configuration.encryption-config.rule : true if[for el2 in el.apply_server_side_encryption_by_default : true if el2.sse_algorithm == "aws:kms"][0] == true][0] == true
    error_message = "Invalid s3 KMS key tags"
  }
}

run "versioning_enabled" {

  variables {
    config = {
      "bucket_name" = "${run.setup_tests.bucket_prefix}-terraform-test-module-s3",
      "type"        = "string",
      "versioning"  = true,
      "objects"     = [],
    }
  }

  command = apply

  ### Test aws_s3_bucket_versioning resource ###
  assert {
    condition     = aws_s3_bucket_versioning.this-versioning.versioning_configuration[0].status == "Enabled"
    error_message = "Invalid s3 bucket versioning status"
  }
}

run "retention_policy_governance" {

  variables {
    config = {
      "bucket_name"      = "${run.setup_tests.bucket_prefix}-terraform-test-module-s3",
      "type"             = "string",
      "versioning"       = true,
      "retention_policy" = { "mode" = "GOVERNANCE", "days" = 1 },
      "objects"          = [],
    }
  }

  command = apply

  ### Test aws_s3_bucket_object_lock_configuration resource ###
  assert {
    condition     = [for el in aws_s3_bucket_object_lock_configuration.object-lock-config[0].rule : true if el.default_retention[0].mode == "GOVERNANCE"][0] == true
    error_message = "Invalid s3 bucket object lock configuration"
  }

  assert {
    condition     = [for el in aws_s3_bucket_object_lock_configuration.object-lock-config[0].rule : true if el.default_retention[0].days == 1][0] == true
    error_message = "Invalid s3 bucket object lock configuration"
  }
}

run "retention_policy_compliance" {

  variables {
    config = {
      "bucket_name"      = "${run.setup_tests.bucket_prefix}-terraform-test-module-s3",
      "type"             = "string",
      "versioning"       = true,
      "retention_policy" = { "mode" = "COMPLIANCE", "years" = 1 },
      "objects"          = [],
    }
  }

  command = apply

  ### Test aws_s3_bucket_object_lock_configuration resource ###
  assert {
    condition     = [for el in aws_s3_bucket_object_lock_configuration.object-lock-config[0].rule : true if el.default_retention[0].mode == "COMPLIANCE"][0] == true
    error_message = "Invalid s3 bucket object lock configuration"
  }

  assert {
    condition     = [for el in aws_s3_bucket_object_lock_configuration.object-lock-config[0].rule : true if el.default_retention[0].years == 1][0] == true
    error_message = "Invalid s3 bucket object lock configuration"
  }
}
