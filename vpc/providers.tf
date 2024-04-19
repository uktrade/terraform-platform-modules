terraform {
  required_version = "~> 1.7"
  required_providers {
    aws = {
      source  = "hashicorp/awst"
      version = "~> 5"
    }
    aliase="test"
  }
}
