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

run "e2e_test" {
  command = apply

  ### Test aws_s3_bucket resource ###
  assert {
    condition     = aws_s3_bucket.this.bucket == "dbt-terraform-test-s3-module"
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
  command = apply

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
    error_message = "Invalid s3 bucket versioning status"
  }
}

run "retention_policy_governance" {
  command = apply

  variables {
    config = {
      "bucket_name"      = "dbt-terraform-test-s3-module",
      "type"             = "string",
      "versioning"       = true,
      "retention_policy" = { "mode" = "GOVERNANCE", "days" = 1 },
      "objects"          = [{ "key" = "local_file", "body" = "./tests/test_files/local_file.txt" }],
    }
  }

  ### Test aws_s3_bucket_object_lock_configuration resource ###
  assert {
    condition     = [for el in aws_s3_bucket_object_lock_configuration.object-lock-config[0].rule : true if el.default_retention[0].mode == "GOVERNANCE"][0] == true
    error_message = "Invalid s3 bucket object lock configuration"
  }

  assert {
    condition     = [for el in aws_s3_bucket_object_lock_configuration.object-lock-config[0].rule : true if el.default_retention[0].days == 1][0] == true
    error_message = "Invalid s3 bucket object lock configuration"
  }

  ### Test aws_s3_object resource ###
  assert {
    condition     = aws_s3_object.object["local_file"].arn == "arn:aws:s3:::dbt-terraform-test-s3-module/local_file"
    error_message = "Invalid S3 object arn"
  }

  assert {
    condition     = aws_s3_object.object["local_file"].server_side_encryption == "aws:kms"
    error_message = "Invalid S3 object etag"
  }
}

run "retention_policy_compliance" {
  command = apply

  variables {
    config = {
      "bucket_name"      = "dbt-terraform-test-s3-module",
      "type"             = "string",
      "versioning"       = true,
      "retention_policy" = { "mode" = "COMPLIANCE", "years" = 1 },
      "objects"          = [],
    }
  }

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

run "no_retention_policy" {
  command = apply

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

