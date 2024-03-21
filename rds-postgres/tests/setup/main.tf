provider "aws" {
  profile = "sandbox"
  shared_config_files = ["~/.aws/config"]
  region = "eu-west-2"
}

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.40"
    }
  }
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "sandbox-postgres"
  }
}
resource "aws_subnet" "primary" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-west-2a"
  tags = {
    Name = "sandbox-postgres-private-primary"
  }
}

resource "aws_subnet" "secondary" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "eu-west-2b"
  tags = {
    Name = "sandbox-postgres-private-secondary"
  }
}