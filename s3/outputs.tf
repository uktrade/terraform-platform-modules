output "s3_kms_arn" {
    value = [ for arn in aws_kms_key.s3_bucket:  arn.arn ]
}
