provider "aws" {
  alias = "domain"
  assume_role {
    role_arn = "arn:aws:iam::${local.dns_account_id}:role/environment-pipeline-assumed-role"
  }
}

provider "aws" {
  region = "us-east-1"
  alias  = "domain-cdn"
  assume_role {
    role_arn = "arn:aws:iam::${local.dns_account_id}:role/environment-pipeline-assumed-role"
  }
}

# provider "datadog" {
#   api_key = data.aws_ssm_parameter.datadog_api_key.value
#   app_key = data.aws_ssm_parameter.datadog_app_key.value
#   api_url = "https://api.datadoghq.eu/"
# }

terraform {
  required_version = "~> 1.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5"
      configuration_aliases = [
        aws.domain,
        aws.domain-cdn
      ]
    }
    # datadog = {
    #   source                = "DataDog/datadog"
    #   version               = "3.57.0" # DG - updated version to latest
    #   configuration_aliases = [datadog.dd]
    # }
  }
}

