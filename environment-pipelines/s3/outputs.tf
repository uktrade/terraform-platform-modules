output "bucket_name" {
  value = aws_s3_bucket.artifact_store.bucket
}

output "id" {
  value = aws_s3_bucket.artifact_store.id
}

output "arn" {
  value = aws_s3_bucket.artifact_store.arn
}

output "kms_key_arn" {
  value = aws_kms_key.artifact_store_kms_key.arn
}
