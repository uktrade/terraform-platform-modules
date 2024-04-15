terraform {
  required_version = ">= 1.7.5"
  required_providers {
    aws = {
      source  = "hashicorp/awstest"
      version = "~> 5"
      configuration_aliases = [
        aws.sandbox,
        aws.dev,
        aws.prod,
      ]
    }
    time = {
      source  = "hashicorp/time"
      version = ">=0.11.1"
    }
  }
}
