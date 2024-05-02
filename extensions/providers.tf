provider "aws" {
  alias = "domain"
  assume_role {
    role_arn = "arn:aws:iam::${var.args.dns_account_id}:role/sandbox-codebuild-assume-role"
  }
}

terraform {
  required_version = "~> 1.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5"
      configuration_aliases = [
        aws.domain,
      ]
    }
  }
}
