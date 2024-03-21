provider "aws" {
  profile = "sandbox"
  shared_config_files = ["~/.aws/config"]
  region = "eu-west-2"
}

variables {
  args = {
    application = "rds-test-postgres"
    environment = "sandbox"
    space = "sandbox-postgres"
    name = "test"
  }
}

run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

run "e2e_test" {
  command = plan

  # assert {
  #   condition = module.this.db_instance.aws_db_instance.engine == "postgres"
  #   error_message = "Invalid SQL engine"
  # }

  # assert {
  #   condition = module.this.db_instance.aws_db_instance.max_allocated_storage <= "100"
  #   error_message = "Don't provision any more than 100GB max allocated space."
  # }

  # assert {
  #   condition = module.this.db_instance.aws_db_instance.db_name == "completePostgresql"
  #   error_message = "Set db_name to 'completePostgresql'"
  # }

  ## Test connection-string in Parameter store
  assert {
    condition = aws_ssm_parameter.connection-string.name == regex("^/copilot/.+/.+/secrets/.+_RDS_POSTGRES$", aws_ssm_parameter.connection-string.name)
    error_message = "Invalid parameter store name"
  }

  assert {
    condition = aws_ssm_parameter.connection-string.type == "SecureString"
    error_message = "Parameter is insecure, please set type to 'SecureString'"
  }
}