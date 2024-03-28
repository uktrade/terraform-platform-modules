# Terraform platform modules

## Testing

The short tests that run against the terraform plan for a module can be run by `cd`-ing into the module folder and running:

```shell
terraform test
```

To run the longer end to end tests that actually deploy the module, do assertions and tear back down are run from the 
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