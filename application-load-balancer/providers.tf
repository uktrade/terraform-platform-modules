terraform {
  required_version = ">= 1.7.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5"
      configuration_aliases = [
        aws.sandbox,
        aws.dev,
        aws.prod,
      ]
    }
  }
}