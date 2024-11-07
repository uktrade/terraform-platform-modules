output "data_dump_kms_key_arn" {
  value = aws_kms_key.data_dump_kms_key.arn
}

output "data_dump_bucket_arn" {
  value = aws_s3_bucket.data_dump_bucket.arn
}