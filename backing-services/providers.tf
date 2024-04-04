terraform {
  required_version = "~> 1.7.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40.0"
    }
  }
}

provider "aws" {
  region                   = "eu-west-2"
  profile                  = "sandbox"
  alias                    = "sandbox"
  shared_credentials_files = ["~/.aws/config"]
}

provider "aws" {
  region                   = "us-east-1"
  profile                  = "dev"
  alias                    = "dev"
  shared_credentials_files = ["~/.aws/config"]
}

provider "aws" {
  region                   = "us-east-1"
  profile                  = "prod"
  alias                    = "prod"
  shared_credentials_files = ["~/.aws/config"]
}
