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

run "aws_s3_bucket_e2e_test" {
  command = apply

  assert {
    condition     = [for el in aws_s3_bucket.this.grant : true if[for el2 in el.permissions : true if el2 == "FULL_CONTROL"][0]][0] == true
    error_message = "Invalid value for aws_s3_bucket.this grant.permissions parameter, should be FULL_CONTROL"
  }

  assert {
    condition     = aws_s3_bucket.this.object_lock_enabled == false
    error_message = "Invalid value for aws_s3_bucket.this object_lock_enabled parameter, should be false"
  }
}

run "aws_kms_key_e2e_test" {
  command = apply

  assert {
    condition     = startswith(aws_kms_key.kms-key.arn, "arn:aws:kms:eu-west-2:852676506468") == true
    error_message = "Invalid value for aws_kms_key arn parameter, should be arn:aws:kms:eu-west-2:852676506468"
  }
}

run "aws_s3_bucket_policy_e2e_test" {
  command = apply

  assert {
    condition     = aws_s3_bucket_policy.bucket-policy.bucket == "dbt-terraform-test-s3-module"
    error_message = "Invalid value for aws_s3_bucket_policy.bucket-policy bucket parameter, should be dbt-terraform-test-s3-module"
  }

  assert {
    condition     = jsondecode(aws_s3_bucket_policy.bucket-policy.policy).Statement[0].Effect == "Deny"
    error_message = "Invalid value for aws_s3_bucket_policy bucket_policy.statement.effect, should be Deny"
  }

  assert {
    condition     = [for el in jsondecode(aws_s3_bucket_policy.bucket-policy.policy).Statement[0].Condition : false if[for el2 in el : true if el2 == "false"][0]][0] == false
    error_message = "Invalid value for aws_s3_bucket_policy bucket_policy.statement.condition.variable, should be aws:SecureTransport"
  }

  assert {
    condition     = jsondecode(aws_s3_bucket_policy.bucket-policy.policy).Statement[0].Action == "s3:*"
    error_message = "Invalid value for aws_s3_bucket_policy bucket_policy.statement.actions, should be s3:*"
  }
}

run "aws_kms_alias_e2e_test" {
  command = apply

  assert {
    condition     = aws_kms_alias.s3-bucket.name == "alias/s3-test-application-s3-test-environment-s3-test-name-key"
    error_message = "Invalid value for aws_kms_alias.s3-bucket name parameter, should be alias/s3-test-application-s3-test-environment-s3-test-name-key"
  }
}

run "aws_s3_object_e2e_test" {
  command = apply

  variables {
    config = {
      "bucket_name" = "dbt-terraform-test-s3-module",
      "type"        = "string",
      "versioning"  = true,
      "objects"     = [{ "key" = "local_file", "body" = "./tests/test_files/local_file.txt" }],
    }
  }

  assert {
    condition     = aws_s3_object.object["local_file"].arn == "arn:aws:s3:::dbt-terraform-test-s3-module/local_file"
    error_message = "Invalid S3 object arn"
  }

  assert {
    condition     = aws_s3_object.object["local_file"].kms_key_id == "arn:aws:kms:eu-west-2:852676506468:key/${aws_kms_key.kms-key.id}"
    error_message = "Invalid kms key id"
  }

  assert {
    condition     = aws_s3_object.object["local_file"].server_side_encryption == "aws:kms"
    error_message = "Invalid S3 object etag"
  }
}
