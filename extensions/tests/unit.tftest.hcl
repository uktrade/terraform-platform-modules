variables {
  args = {
    application = "test-application",
    services = {
      "test-s3" : {
        "type" : "s3",
        "services" : ["web"],
        "bucket_name" : "extensions-test-bucket",
        "versioning" : false,
        "environments" : {
          "test" : {
            "bucket_name" : "extensions-test-bucket",
            "versioning" : false
          }
        }
      },
      "test-opensearch" : {
        "type" : "opensearch",
        "name" : "test-name"
        "engine" : "2.11",
        "instance" : "t3.small.search",
        "instances" : 1,
        "volume_size" : 200,
        "master" : false,
        "environments" : {
          "test" : {
          }
        }
      }
    }
  }
  application = "test-application"
  environment = "test-environment"
  vpc_name    = "test-vpc"
}

mock_provider "aws" {
  alias = "prod"
}

mock_provider "aws" {
  alias = "domain"
}

override_data {
  target = module.opensearch["test-opensearch"].data.aws_vpc.vpc
  values = {
    id         = "vpc-00112233aabbccdef"
    cidr_block = "10.0.0.0/16"
  }
}

override_data {
  target = module.opensearch["test-opensearch"].data.aws_subnets.private-subnets
  values = {
    ids = ["subnet-000111222aaabbb01", ]
  }
}

run "aws_ssm_parameter_unit_test" {
  command = plan

  ### Test aws_ssm_parameter resource ###
  assert {
    condition     = aws_ssm_parameter.addons.name == "/copilot/applications/test-application/environments/test-environment/addons"
    error_message = "Invalid config for aws_ssm_parameter name"
  }

  assert {
    condition     = aws_ssm_parameter.addons.type == "String"
    error_message = "Invalid config for aws_ssm_parameter type"
  }

  assert {
    condition     = aws_ssm_parameter.addons.tags["application"] == "test-application"
    error_message = ""
  }

  assert {
    condition     = aws_ssm_parameter.addons.tags["copilot-application"] == "test-application"
    error_message = ""
  }

  assert {
    condition     = aws_ssm_parameter.addons.tags["environment"] == "test-environment"
    error_message = ""
  }

  assert {
    condition     = aws_ssm_parameter.addons.tags["copilot-environment"] == "test-environment"
    error_message = ""
  }

  assert {
    condition     = aws_ssm_parameter.addons.tags["managed-by"] == "DBT Platform - Terraform"
    error_message = ""
  }
}
