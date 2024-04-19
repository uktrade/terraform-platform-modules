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
      "test-opensearch": {
        "type": "opensearch",
        "environments": {
          "test": {
            "plan": "small",
            "engine": "2.11",
            "volume_size": 200
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
    condition = jsondecode(aws_ssm_parameter.addons.value) == {
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
      }
    }
    error_message = "Invalid config for aws_ssm_parameter value"
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
