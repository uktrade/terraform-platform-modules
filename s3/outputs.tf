output "bucket_name" {
  value = aws_s3_bucket.this.bucket
}

output "id" {
  value = aws_s3_bucket.this.id
}

output "arn" {
  value = aws_s3_bucket.this.arn
}

output "kms_key_arn" {
  value = var.config.serve_static ? null: aws_kms_key.kms-key.arn
}
