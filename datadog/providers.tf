terraform {
  required_version = "~> 1.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5"
    }
    datadog = {
      source  = "DataDog/datadog"
      version = "3.57.0" # DG - updated version to latest
      configuration_aliases = [ datadog.dd ]
    }
  }
}

/*
provider "datadog" {
  api_key = data.aws_ssm_parameter.datadog_api_key.value
  app_key = data.aws_ssm_parameter.datadog_app_key.value
  api_url = "https://api.datadoghq.eu/"
}
*/
