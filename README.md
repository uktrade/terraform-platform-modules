# Terraform Platform Modules

## Setup

```shell
   pip install poetry && poetry install && poetry run pre-commit install
```

## Testing

The short tests that run against the `terraform plan` for a module can be run by `cd`-ing into the module folder and running:

```shell
terraform test
```

To run the longer end-to-end tests that actually deploy the module (via `terraform apply`), perform assertions and tear back down are run from the 
same directory as follows:

```shell
terraform test -test-directory e2e-tests
```

## Backing services module

This module is configured by a YAML file and two simple args:

```terraform
locals {
  args = {
    application = "my-app-tf"
    services    = yamldecode(file("extensions.yml"))
  }
}

module "extensions" {
  source     = "git::ssh://git@github.com/uktrade/terraform-platform-modules.git//extensions?depth=1&ref=main"

  args        = local.args
  environment = "my-env"
  vpc_name    = "my-vpc-name"
}
```

## Opensearch module configuration options

The options available for configuring the opensearch module should be applied in the `extensions.yml` file. They 
should look something like this:

```yaml
my-opensearch:
  type: opensearch
  environments:
    "*":  # Default configuration values
      plan: small
      engine: '2.11'
      ebs_volume_type: gp3  # Optional. Must be one of: standard, gp2, gp3, io1, io2, sc1 or st1. Defaults to gp2.
      ebs_throughput: 500   # Optional. Throughput in MiB/s. Only relevant for volume type gp3. Defaults to 250 MiB/s.
      index_slow_log_retention_in_days: 3   # Optional. Valid values can be found here: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group#retention_in_days
      search_slow_log_retention_in_days: 14 # Optional. As above.
      es_app_log_retention_in_days: 30      # Optional. As above.
      audit_log_retention_in_days: 1096     # Optional. As above.
      # The following are derived from the plan. DBTP-841 will allow them to be overriden here.
      #    volume_size: 1000
      #    instances: 1
      #    master: false
      #    instance: m6g.xlarge.search
    env-one:  # Per-environment overrides for any of the defaults in the previous section
      plan: large    # Override the plan.
      engine: '2.7'  # Downgrade the engine.
```

## Application Load Balancer module

This module will create a ALB that lets you specify multiple domain names for use in the HTTPS listener rule.  In addition it will create the required certificates for all the domains specified.

The primary domain will always follow the pattern:

For non-production: `internal.<application_name>.uktrade.digital`

For production: `internal.<application_name>.prod.uktrade.digital`



If there are multiple web services on the application, you can add the additional domain to your certificate by adding the prefix name (eg. `internal.static`) to the variable `additional_address_list` see extension.yml example below.  `Note: this is just the prefix, no need to add env.uktrade.digital`

`cdn_domains_list` and `additional_address_list` are optional.

### Route 53 record creation

The R53 domains for non-production and production are stored in different AWS accounts.  The last half of the Terraform code needs to be able to run in the correct AWS account.  This is determined by the provider passed in from the `<application>-deploy` `aws-domain` alias.

example `extensions.yml` config.

```yaml
my-application-alb:
  type: alb
  environments:
    dev: 
      additional_address_list:
        - internal.my-web-service-2
```

## CDN

This module will create the CloudFront (CDN) endpoints for the application if enabled.

`cdn_domains_list` is a map of the domain names that will be configured in CloudFront.
* the key is the fully qualified domain name
* the value is an array containing the internal prefix and the base domain (the application's Route 53 zone).  

example `extensions.yml` config.

```yaml
my-application-alb:
  type: alb
  environments:
    dev: 
      cdn_domains_list:
        - dev.my-application.uktrade.digital: [ "internal", "my-application.uktrade.digital" ] 
        - dev.my-web-service-2.my-application.uktrade.digital: [ "internal.my-web-service-2", "my-application.uktrade.digital" ]
      additional_address_list:
        - internal.my-web-service-2
      enable_cdn_record: false
      enable_logging: true
    prod:
      cdn_domains_list: {my-application.great.gov.uk: "great.gov.uk"} 
```


### Optional settings:

To create a R53 record pointing to the CloudFront endpoint, set this to true.  If not set, in non production this is set to true by default and set to false in production.
- enable_cdn_record: true

To turn on CloudFront logging to a S3 bucket, set this to true.
- enable_logging: true


## Monitoring

This will provision a CloudWatch Compute Dashboard and Application Insights for `<application>-<environment>`.

Example usage in `extensions.yml`...

```yaml
demodjango-monitoring:
  type: monitoring
  environments:
    "*":
      enable_ops_center: false
    prod:
      enable_ops_center: true
```

## Using our `demodjango` application for testing

Note: We are currently treating the `terraform-deployment` branch as our `main` branch for this work.

- Terraform
  - Edit the `environment` and `vpc_name` under `module.extensions-tf` in `terraform/<environment>/main.tf`
  - `cd terraform`
  - `terraform apply`
- AWS Copilot
  - `cd ..`
    - Make any required changes to have valid AWS Copilot configuration for your environment
      - Copy the VPC IDs, Subnet IDs and certificate ARN from the AWS Console to your environment manifest
      - Set the alias and copy the Application Load Balancer ARN from the AWS console to the `http` section for your environment in `copilot/web/manifest.yml`
      ```
      <environment>:
        http:
          alb: arn:aws:elasticloadbalancing:eu-west-2:852676506468:loadbalancer/app/demodjango-<environment>/bc968fa0a4fcd257
          alias: internal.<environment>.demodjango.uktrade.digital
      ```
  - Add the `DJANGO_SECRET_KEY` secret for you environment `copilot secret init --name DJANGO_SECRET_KEY --values <environment>='<something_random>'`
  - Deploy environment
    - `copilot app init demodjango`
    - `copilot env init --name <environment> --profile $AWS_PROFILE --default-config`
    - `copilot env deploy --name <environment>`
  - Deploy the web service with bootstrap image
    - Set the `web` service to use the `copilot-bootstrap` image for now
    - `copilot svc init --name web`
    - `IMAGE_TAG=tag-latest copilot svc deploy --name web --env <environment>`
    - Test it loads OK
    - Swap to the proper image in the `web` manifest
    - `IMAGE_TAG=tag-latest copilot svc deploy --name web --env <environment>`
    - Test it loads OK, Celery checks will still fail for now
  - Deploy Celery services
    - `copilot svc init --name celery-worker`
    - `IMAGE_TAG=tag-latest copilot svc deploy --name celery-worker --env <environment>`
    - Skip next two, need to pull in the Celery Beat stuff from `main`...
      - `copilot svc init --name celery-beat`
      - `IMAGE_TAG=tag-latest copilot svc deploy --name celery-beat --env <environment>`
    - Test the web service loads OK, including Celery checks
