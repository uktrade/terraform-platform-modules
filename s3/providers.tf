terraform {
  required_version = "~> 1.7"
  requied_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5"
    }
  }
}
