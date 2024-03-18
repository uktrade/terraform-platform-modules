terraform {
  required_version = ">=1.6.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

data "aws_caller_identity" "current" {}

module "this" {
  depends_on = [aws_kms_key.s3-bucket]
  source     = "terraform-aws-modules/s3-bucket/aws"
  version    = ">=1.6.1"
  # Todo (spike): Should add a unique string in the bucket name to avoid duplication.
  bucket = var.config.params.bucket_name

  # versioning = {
  #   enabled = true
  # }

  attach_policy = true
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "ForceHTTPS",
        "Effect" : "Deny",
        "Principal" : "*",
        "Action" : "s3:*",
        "Resource" : [
          "arn:aws:s3:::${var.config.params.bucket_name}/*",
          "arn:aws:s3:::${var.config.params.bucket_name}"
        ],
        "Condition" : {
          "Bool" : {
            "aws:SecureTransport" : "false"
          }
        }
      }
    ]
  })

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = aws_kms_key.s3-bucket.id
        sse_algorithm     = "aws:kms"
      }
    }
  }

  tags = local.tags
}

resource "aws_kms_key" "s3-bucket" {
  description = "KMS Key for S3 encryption"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Id" : "${var.application}-${var.application}S3Bucket-key",
    "Statement" : [
      {
        "Sid" : "Enable IAM User Permissions",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        "Action" : "kms:*",
        "Resource" : "*"
      }
    ]
  })
  tags = local.tags
}

resource "aws_kms_alias" "s3-bucket" {
  depends_on    = [aws_kms_key.s3-bucket]
  name          = "alias/${var.application}-${var.application}S3Bucket-key"
  target_key_id = aws_kms_key.s3-bucket.id
}

## Commenting these out as we may need to come back to investigating these
# resource "aws_ssm_parameter" "s3-kms-arn" {
#   for_each = toset(var.environment)
#   name  = "/copilot/${var.application}/${each.value}/secrets/${upper("${var.application}_s3_kms_arn")}"
#   type  = "String"
#   value = aws_kms_key.s3-bucket[each.key].arn
#   tags = {
#         copilot-application = var.application
#         copilot-environment = "${each.value}"
#         managed-by = "Terraform"
#     }
# }

# resource "null_resource" "get_terraform_version" {
#   #triggers = { always_run = "${timestamp()}" }
#   provisioner "local-exec" {
#     command = "echo $(terraform --version | sed 1q) > ${path.module}/terraform_version.txt"
#   }
# }

# data "local_file" "terraform_version" {
#   filename   = "${path.module}/terraform_version.txt"
#   depends_on = [null_resource.get_terraform_version]
# }

