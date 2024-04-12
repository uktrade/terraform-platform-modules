variables {
  args = {
    application = "test-application",
    services    = {}
  }
  application = "test-application"
  environment = "test-environment"
  vpc_name    = "test-vpc"
}

provider "aws" {
  region                   = "eu-west-2"
  profile                  = "sandbox"
  alias                    = "prod"
  shared_credentials_files = ["~/.aws/config"]
}

run "aws_ssm_parameter_unit_test" {
  command = apply

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
    condition     = aws_ssm_parameter.addons.value == "{}"
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
