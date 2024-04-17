terraform {
  required_version = "~> 1.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5"
    }
  }
}

provider "aws" {
  region                   = "eu-west-2"
  profile                  = "dev"
  alias                    = "domain"
  shared_credentials_files = ["~/.aws/config"]
}
