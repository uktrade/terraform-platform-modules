variables {
  args = {
    application = "test-application",
    services = {
      "test-s3" : {
        "type" : "s3",
        "services" : ["web"],
        "environments" : {
          "test-environment" : {
            "bucket_name" : "extensions-test-bucket",
            "versioning" : false
          },
          "other-environment" : {
            "bucket_name" : "other-environment-extensions-test-bucket",
            "versioning" : false
          }
        }
      },
      "test-opensearch" : {
        "type" : "opensearch",
        "name" : "test-small",
        "environments" : {
          "test-environment" : {
            "engine" : "2.11",
            "plan" : "small",
            "volume_size" : 512
          },
          "other-environment" : {
            "engine" : "2.11",
            "plan" : "small",
            "volume_size" : 512
          }
        }
      }
    },
    dns_account_id = "123456"
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

mock_provider "aws" {
  alias = "domain-cdn"
}

mock_provider "aws" {}

override_data {
  target = module.opensearch["test-opensearch"].data.aws_caller_identity.current
  values = {
    account_id = "001122334455"
  }
}

override_data {
  target = module.opensearch["test-opensearch"].data.aws_iam_policy_document.assume_ecstask_role
  values = {
    json = "{\"Sid\": \"AllowAssumeECSTaskRole\"}"
  }
}

override_data {
  target = module.opensearch["test-opensearch"].data.aws_ssm_parameter.log-destination-arn
  values = {
    value = "{\"dev\":\"arn:aws:logs:eu-west-2:763451185160:log-group:/copilot/tools/central_log_groups_dev\",\"prod\":\"arn:aws:logs:eu-west-2:763451185160:log-group:/copilot/tools/central_log_groups_prod\"}"
  }
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
    ids = ["subnet-000111222aaabbb01", "subnet-000111222aaabbb02", ]
  }
}

run "aws_ssm_parameter_unit_test" {
  command = plan

  # Configuration
  assert {
    condition     = aws_ssm_parameter.addons.name == "/copilot/applications/test-application/environments/test-environment/addons"
    error_message = "Invalid config for aws_ssm_parameter name"
  }
  assert {
    condition     = aws_ssm_parameter.addons.tier == "Intelligent-Tiering"
    error_message = "Intelligent-Tiering not enabled, parameters > 4096 characters will be rejected"
  }
  assert {
    condition     = aws_ssm_parameter.addons.type == "String"
    error_message = "Invalid config for aws_ssm_parameter type"
  }

  # Value only includes current environment
  assert {
    condition     = strcontains(aws_ssm_parameter.addons.value, "test-environment")
    error_message = ""
  }
  assert {
    condition     = strcontains(aws_ssm_parameter.addons.value, "other-environment") == false
    error_message = ""
  }

  # Tags
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

run "s3_service_test" {
  command = plan

  assert {
    condition     = output.resolved_config.test-s3.bucket_name == "extensions-test-bucket"
    error_message = "Should be: extensions-test-bucket"
  }

  assert {
    condition     = output.resolved_config.test-s3.type == "s3"
    error_message = "Should be: s3"
  }

  assert {
    condition     = output.resolved_config.test-s3.versioning == false
    error_message = "Should be: false"
  }
}

run "opensearch_plan_small_service_test" {
  command = plan

  assert {
    condition     = output.resolved_config.test-opensearch.engine == "2.11"
    error_message = "Should be: 2.11"
  }

  assert {
    condition     = output.resolved_config.test-opensearch.instance == "t3.medium.search"
    error_message = "Should be: t3.medium.search"
  }

  assert {
    condition     = output.resolved_config.test-opensearch.instances == 1
    error_message = "Should be: 1"
  }

  assert {
    condition     = output.resolved_config.test-opensearch.master == false
    error_message = "Should be: false"
  }

  assert {
    condition     = output.resolved_config.test-opensearch.name == "test-small"
    error_message = "Should be: test-small"
  }

  assert {
    condition     = output.resolved_config.test-opensearch.type == "opensearch"
    error_message = "Should be: opensearch"
  }

  assert {
    condition     = output.resolved_config.test-opensearch.volume_size == 512
    error_message = "Should be: 512"
  }
}

run "opensearch_plan_medium_ha_service_test" {
  variables {
    args = {
      application = "test-application",
      services = {
        "test-opensearch" : {
          "type" : "opensearch",
          "name" : "test-medium-ha"
          "environments" : {
            "test-environment" : {
              "engine" : "2.11",
              "plan" : "medium-ha"
            }
          }
        }
      },
      dns_account_id = "123456"
    }
    environment = "test-environment"
    vpc_name    = "test-vpc"
  }

  command = plan

  assert {
    condition     = output.resolved_config.test-opensearch.engine == "2.11"
    error_message = "Should be: 2.11"
  }

  assert {
    condition     = output.resolved_config.test-opensearch.instance == "m6g.large.search"
    error_message = "Should be: m6g.large.search"
  }

  assert {
    condition     = output.resolved_config.test-opensearch.instances == 2
    error_message = "Should be: 2"
  }

  assert {
    condition     = output.resolved_config.test-opensearch.master == false
    error_message = "Should be: false"
  }

  assert {
    condition     = output.resolved_config.test-opensearch.name == "test-medium-ha"
    error_message = "Should be: test-medium-ha"
  }

  assert {
    condition     = output.resolved_config.test-opensearch.type == "opensearch"
    error_message = "Should be: opensearch"
  }

  assert {
    condition     = output.resolved_config.test-opensearch.volume_size == 512
    error_message = "Should be: 512"
  }
}
