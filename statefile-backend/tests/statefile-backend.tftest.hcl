provider "aws" {
  profile = "sandbox"
  shared_config_files = ["~/.aws/config"]
  region = "eu-west-2"
}

variables {
  aws_account_name = "sandbox-statefile-test"
}

run "e2e_test" {
  command = apply

  # Bucket
  assert {
    condition = aws_s3_bucket.terraform-state.bucket == "terraform-platform-state-${var.aws_account_name}"
    error_message = "Invalid bucket name"
  }

  assert {
    condition = aws_s3_bucket.terraform-state.tags["purpose"] != ""
    error_message = "Please enter purpose tag"
  }

  # Bucket ACL
  assert {
    condition = aws_s3_bucket_acl.terraform-state-acl.bucket == aws_s3_bucket.terraform-state.id
    error_message = "The bucket ACL is not attached to the terraform state bucket"
  }
  
  # Bucket Versioning
  assert {
    condition = aws_s3_bucket_versioning.terraform-state-versioning.bucket == aws_s3_bucket.terraform-state.id
    error_message = "Ensure the aws_s3_bucket_versioning resource is attached to the correct S3 bucket"
  }
  assert {
    condition = aws_s3_bucket_versioning.terraform-state-versioning.versioning_configuration[0].status == "Enabled"
    error_message = "Bucket Versioning must be enabled"
  }

  # Bucket ownership control
  assert {
    condition = aws_s3_bucket_ownership_controls.terraform-state-ownership.bucket == aws_s3_bucket.terraform-state.id
    error_message = "Ensure the aws_s3_bucket_ownership_controls resource is attached to the correct S3 bucket"
  }
  assert {
    condition = aws_s3_bucket_ownership_controls.terraform-state-ownership.rule[0].object_ownership == "BucketOwnerPreferred"
    error_message = "Set object_ownership to 'BucketOwnerPreferred'"
  }

  # Bucket public access block
  assert {
    condition = aws_s3_bucket_public_access_block.block.bucket == aws_s3_bucket.terraform-state.id
    error_message = "Ensure the aws_s3_bucket_public_access_block resource is attached to the correct s3 bucket"
  }
  assert {
    condition = aws_s3_bucket_public_access_block.block.block_public_acls == true
    error_message = "'block_public_acls' must be set to true in the aws_s3_bucket_public_access_block resource"
  }
  assert {
    condition = aws_s3_bucket_public_access_block.block.block_public_policy == true
    error_message = "'block_public_policy' must be set to true in the aws_s3_bucket_public_access_block resource"
  }
  assert {
    condition = aws_s3_bucket_public_access_block.block.ignore_public_acls == true
    error_message = "'ignore_public_acls' must be set to true in the aws_s3_bucket_public_access_block resource"
  }
  assert {
    condition = aws_s3_bucket_public_access_block.block.restrict_public_buckets == true
    error_message = "'restrict_public_buckets' must be set to true in the aws_s3_bucket_public_access_block resource"
  }

  # Bucket server side encryption
  assert {
    condition = aws_s3_bucket_server_side_encryption_configuration.terraform-state-sse.bucket == aws_s3_bucket.terraform-state.id
    error_message = "Ensure the aws_s3_bucket_server_side_encryption_configuration resource is attached to the correct s3 bucket"
  }
  assert {
    # This attribute don't have an index to reference, so we have to iterate through it in a couple of for loops. 
    # Since a for loop requires a list ('[]') or a map ('{}'), we need to reference the first entry in each of the three lists we create here, hence the '[0]'s at the end.
    condition =[ for rule in aws_s3_bucket_server_side_encryption_configuration.terraform-state-sse.rule : true if [ for sse in rule.apply_server_side_encryption_by_default : true if[sse.sse_algorithm == "aws:kms"][0]][0]][0] == true
    error_message = "You must use KMS for server side encryption on this bucket"
  }

  # DynamoDB table
  assert {
    condition = aws_dynamodb_table.terraform-state.name ==  "terraform-platform-lockdb-${var.aws_account_name}"
    error_message = "Invalid name for dynamoDB table"
  }
  assert {
    condition = aws_dynamodb_table.terraform-state.read_capacity >= 20
    error_message = "The read_capacity is set too low. Minimum == 20"
  }
  assert{
    condition = aws_dynamodb_table.terraform-state.write_capacity >= 20
    error_message = "The write_capacity is set too low. Minimum == 20"
  }
  assert {
    condition = aws_dynamodb_table.terraform-state.hash_key == "LockID"
    error_message = "The DynamoDB table requires the partition (or 'hash') key to be 'LockID'"
  }
  assert {
    condition = [for att in aws_dynamodb_table.terraform-state.attribute : true if [att.name == "LockID" && att.type == "S"][0]][0] == true
    error_message = "The 'LockID' key must be of type string ('S')"
  }

  # KMS Key
  assert {
    condition = aws_kms_alias.key-alias.target_key_id == aws_kms_key.terraform-bucket-key.id
    error_message = "Ensure the KMS alias is assigned to the correct KMS key"
  }
  assert {
    condition = aws_kms_alias.key-alias.name == "alias/terraform-platform-state-s3-key-${var.aws_account_name}"
    error_message = "KMS key alias is incorrect"
  }
}

