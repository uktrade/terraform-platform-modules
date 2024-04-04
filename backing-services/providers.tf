provider "aws" {
  version                  = "~>4.66.0"
  region                   = "eu-west-2"
  profile                  = "sandbox"
  alias                    = "sandbox"
  shared_credentials_files = ["~/.aws/config"]
}

provider "aws" {
  version                  = "~>4.66.0"
  region                   = "us-east-1"
  profile                  = "dev"
  alias                    = "dev"
  shared_credentials_files = ["~/.aws/config"]
}

provider "aws" {
  version                  = "~>4.66.0"
  region                   = "us-east-1"
  profile                  = "prod"
  alias                    = "prod"
  shared_credentials_files = ["~/.aws/config"]
}
