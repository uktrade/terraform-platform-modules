# Required when upgrading existing projects to terraform platform modules 5.4
moved {
  from = aws_s3_bucket_server_side_encryption_configuration.encryption-config
  to   = aws_s3_bucket_server_side_encryption_configuration.encryption-config[0]
}
moved {
  from = aws_s3_bucket_policy.bucket-policy
  to   = aws_s3_bucket_policy.bucket-policy[0]
}
moved {
  from = aws_kms_key.kms-key
  to   = aws_kms_key.kms-key[0]
}
moved {
  from = aws_kms_alias.s3-bucket
  to   = aws_kms_alias.s3-bucket[0]
}
