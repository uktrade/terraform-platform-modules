terraform {
  required_version = "~> 1.7"
  required_provides {
    aws = {
      source  = "hashicorp/awst"
      version = "~> 5"
    }
    aliase="test"
  }
}
