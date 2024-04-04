#test3
# Terraform platform modules

## Testing

The short tests that run against the `terraform plan` for a module can be run by `cd`-ing into the module folder and running:

```shell
terraform test
```

To run the longer end to end tests that actually deploy the module (via `terrafrom apply`), perform assertions and tear back down are run from the 
same directory as follows:

```shell
terraform test -test-directory e2e-tests
```

## Backing services module

This module is configured by a yaml file and two simple args:

```terraform
locals {
  args = {
    application = "my-app-tf"
    services    = yamldecode(file("backing-services.yml"))
  }
}

module "backing-services" {
  source     = "git::ssh://git@github.com/uktrade/terraform-platform-modules.git//backing-services?depth=1&ref=main"

  args        = local.args
  environment = "my-env"
  vpc_name    = "my-vpc-name"
}
```

## Opensearch module configuration options

The options available for configuring the opensearch module should be applied in the `backing-services.yml` file. They 
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
      name: my-app-env-one  # The name of the opensearch instance. 28 char limit and unique per account.
      plan: large    # Override the plan.
      engine: '2.7'  # Downgrade the engine.
```

## Application Load Balancer module

This module will create a ALB that lets you specify multiple domain names for use in the HTTPS listener rule.  In addition it will create the required certificates for all the domains specified.

The primary domain will always follow the pattern:

For non-production: `internal.<application_name>.uktrade.digital`

For production: `internal.<application_name>.prod.uktrade.digital`

Additional domains (cdn_domains_list) are the domain names that will be configured in CloudFront.   

### Route 53 record creation

The R53 domains for non production and production are stored in different AWS accounts.  The last half of the Terraform code needs to be able to run in the correct AWS account.  This where the environment check is used and the appropriate provider is defined.

example `backing-services.yml` config.

```yaml
my-application-alb:
  type: alb
  environments:
    dev: 
      cdn_domains_list: {dev.my-application.uktrade.digital: "my-application.uktrade.digital"} 
    prod:
      domain: {my-application.great.gov.uk: "great.gov.uk"} 
```

## Monitoring

This will provision a CloudWatch Compute Dashboard and Application Insights for `<application>-<environment>`.

Example usage in `backing-services.yml`...

```yaml
demodjango-tf-monitoring:
  type: monitoring
  environments:
    "*":
      enable_ops_center: false
    prod:
      enable_ops_center: true
```

