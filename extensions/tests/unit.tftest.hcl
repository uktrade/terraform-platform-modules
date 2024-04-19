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
        "name" : "test-small"
        "engine" : "2.11",
        "plan" : "small"
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
    ids = ["subnet-000111222aaabbb01", "subnet-000111222aaabbb02", ]
  }
}

run "aws_ssm_parameter_unit_test" {
  command = plan

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

run "s3_service_test" {
  command = plan

  assert {
    condition     = output.resolved_config.test-s3.bucket_name == "extensions-test-bucket"
    error_message = "Invalid value for resolved_config.test-s3 bucket_name parameter, should be extensions-test-bucket"
  }

  assert {
    condition     = output.resolved_config.test-s3.type == "s3"
    error_message = "Invalid value for resolved_config.test-s3 type parameter, should be s3"
  }

  assert {
    condition     = output.resolved_config.test-s3.versioning == false
    error_message = "Invalid value for resolved_config.test-s3 versioning parameter, should be false"
  }
}

run "opensearch_plan_small_service_test" {
  command = plan

  assert {
    condition     = output.resolved_config.test-opensearch.engine == "2.11"
    error_message = "Invalid value for resolved_config.test-opensearch engine parameter, should be 2.11"
  }

  assert {
    condition     = output.resolved_config.test-opensearch.instance == "t3.medium.search"
    error_message = "Invalid value for resolved_config.test-opensearch instance parameter, should be t3.medium.search"
  }

  assert {
    condition     = output.resolved_config.test-opensearch.instances == 1
    error_message = "Invalid value for resolved_config.test-opensearch instances parameter, should be 1"
  }

  assert {
    condition     = output.resolved_config.test-opensearch.master == false
    error_message = "Invalid value for resolved_config.test-opensearch master parameter, should be false"
  }

  assert {
    condition     = output.resolved_config.test-opensearch.name == "test-small"
    error_message = "Invalid value for resolved_config.test-opensearch name parameter, should be test-small"
  }

  assert {
    condition     = output.resolved_config.test-opensearch.type == "opensearch"
    error_message = "Invalid value for resolved_config.test-opensearch type parameter, should be opensearch"
  }

  assert {
    condition     = output.resolved_config.test-opensearch.volume_size == 200
    error_message = "Invalid value for resolved_config.test-opensearch volume_size parameter, should be 200"
  }
}

run "opensearch_plan_medium_ha_service_test" {
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
          "name" : "test-medium-ha"
          "engine" : "2.11",
          "plan" : "medium-ha"
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

  command = plan

  assert {
    condition     = output.resolved_config.test-opensearch.engine == "2.11"
    error_message = "Invalid value for resolved_config.test-opensearch engine parameter, should be 2.11"
  }

  assert {
    condition     = output.resolved_config.test-opensearch.instance == "m6g.large.search"
    error_message = "Invalid value for resolved_config.test-opensearch instance parameter, should be m6g.large.search"
  }

  assert {
    condition     = output.resolved_config.test-opensearch.instances == 2
    error_message = "Invalid value for resolved_config.test-opensearch instances parameter, should be 2"
  }

  assert {
    condition     = output.resolved_config.test-opensearch.master == false
    error_message = "Invalid value for resolved_config.test-opensearch master parameter, should be false"
  }

  assert {
    condition     = output.resolved_config.test-opensearch.name == "test-medium-ha"
    error_message = "Invalid value for resolved_config.test-opensearch name parameter, should be test-medium-ha"
  }

  assert {
    condition     = output.resolved_config.test-opensearch.type == "opensearch"
    error_message = "Invalid value for resolved_config.test-opensearch type parameter, should be opensearch"
  }

  assert {
    condition     = output.resolved_config.test-opensearch.volume_size == 512
    error_message = "Invalid value for resolved_config.test-opensearch volume_size parameter, should be 512"
  }
}
