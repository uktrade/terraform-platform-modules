# Terraform platform modules

## Using [Terraform workspaces](https://developer.hashicorp.com/terraform/language/state/workspaces) for development

In your `<application>-deploy` codebase:

- `aws sso login`
- `cd terraform`
- `terraform init`
- If first time `terraform workspace new <workspace>` else `terraform workspace select <workspace>`
  - `workspace` will normally be the name of your environment
- Change name of environments/spaces in `<application>.tf` to your environment/space
  - This step should go away in due course, but for now we need to do this and not commit the changes to `main`
- `terraform plan|apply`

## Testing

_terraform-platform-modules_ seems to need `sandbox` AWS account login but no _.envrc_ file in repo. Had to manually export these for running the Terraform tests and `aws sso login`:
```
export AWS_PROFILE=sandbox
export AWS_REGION=eu-west-2
export AWS_DEFAULT_REGION=eu-west-2
```


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

This module is configured by a yaml file and two simple args:

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

Additional domains (cdn_domains_list) are the domain names that will be configured in CloudFront.   

### Route 53 record creation

The R53 domains for non production and production are stored in different AWS accounts.  The last half of the Terraform code needs to be able to run in the correct AWS account.  This where the environment check is used and the appropriate provider is defined.

example `extensions.yml` config.

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

Note:  We are currently treating the terraform-deployment branch on the _demodjango-deploy_ repository as our `main` branch for this work.

### Task: Deploy a Virtual Private Cloud using the VPC Terraform module

Repository to execute code: _terraform-platform_

#### How to use

In _terraform-platform_ repository, `dbt-platform/dev/vpc` directory, there are two Terraform files that need to be updated when adding new AWS accounts or creating new VPCs: 
- `providers.tf` 
- `vpcs.tf`.

#### providers.tf

This file will contain a map of all AWS accounts that will have VPCs managed by this Terraform code.  If a new AWS account is needed add a new entry as per example.

```terraform
provider "aws" {
  region                   = "eu-west-2"
  profile                  = "profile_name_of_aws_account"
  alias                    = "profile_name_of_aws_account"
  shared_credentials_files = ["~/.aws/config"]
}
```

#### vpcs.tf

Here you define a new module per AWS account, within that module you can specify multiple VPCs.  The module will contain the VPC's unique configuration and will in-turn call the main VPC module that deploys the VPC.

example modules
```terraform
module "vpc-<name_of_dev_aws_account>" {
  for_each  =  {
      "name_of_dev_vpc_1" = {
          cidr         = "10.0"
          nat_gateways = local.nat_gateways_dev
          az_map       = local.az_map_dev
        }
      "name_of_dev_vpc_2" = {
           cidr         = "10.1"
           nat_gateways = local.nat_gateways_dev
           az_map       = local.az_map_dev
         }
    }
  
  source = "../../../tf-vpc-module"
  providers =  { aws = aws.sandbox }
  arg_key = each.key
  arg_value = each.value
}


module "vpc-<name_of_dev_aws_account>" {
  for_each = {
      "name_of_prod_vpc" = {
          cidr         = "10.2"
          nat_gateways = local.nat_gateways_prod
          az_map       = local.az_map_prod
        }
    }

  source = "../../../tf-vpc-module"
  providers = { aws = aws.platform-sandbox}
  arg_key = each.key
  arg_value = each.value
}
```

VARIABLES

- Module name:
The naming convention is `vpc-<name_of_aws_account>`
eg. `vpc-sandbox`

- VPC name:
What you want to call the VPC.
eg. `sandbox`

- cidr:
Here you enter in the first 2 Octets of the VPC network address.  This should be sequential, so make a note of previous CIDR and increment by one.  This value has to be unique unless the VPC is ephemeral, e.g. used for review apps.
eg. `10.1`

- nat_gateways:
There are two options here, `local.nat_gateways_dev` and `local.nat_gateways_prod`.  For dev we only need to deploy the 1 NAT gateway and for prod we deploy 3 NAT gateways.

- az_map:
There are two options here, `local.az_map_dev` and `local.az_map_prod`.  This defines how many availability zones the subnets are deployed into.  For dev we only need two, for prod we have all three.

---

### Task: Deploy environment infrastructure using Terraform and AWS Copilot

Repository required: _demodjango_deploy_

- Terraform

  In order to get the Terraform part working:
  - Need to have a _prod_ profile with the following configuartion in ~/.aws/config file
  - “Failed to get shared config profile, prod” will appear if you don’t have a _prod_ profile set up
    ```
      [profile prod]
      sso_start_url = https://uktrade.awsapps.com/start
      sso_region = eu-west-2
      sso_account_id = 684092750218
      sso_role_name = AdministratorAccess
      region = eu-west-2
      output = json
    ```

  - `terraform/demodjango.tf`, edit the `environment` and `vpc_name` under `module.extensions-tf` code block to use your name for the `environment` value and the name of the VPC you provisioned in the previous step, eg:
  
    ``` terraform
      module "extensions-tf" {
      # Use this source when testing with local module
      # source = "../../terraform-platform-modules/extensions"
      source = "git::ssh://git@github.com/uktrade/terraform-platform-modules.git//extensions?depth=1&ref=main"

      args        = local.args
      environment = "homer"
      vpc_name    = "sandbox-homer"
      }
    ```
  - You may wish to use the local `source` for the module code when testing
  
  - `terraform/extensions.yml` add bucket config for the new environment to `demodjango-s3-bucket` code block
    ``` terraform
      environments:
        <environment>:
          bucket_name: demodjango-<environment>
          versioning: false
    ```

  - `cd terraform`
  - Create or select a Terraform workspace for your environment 
    ``` terraform
      terraform workspace new|select <environment>
    ```
  - `terraform apply`
  
  
- AWS Copilot
  - cd into `copilot` directory
      - `copilot/environments/<environment>/manifest.yml`, copy the VPC IDs and Subnet IDs from the AWS Console to your environment manifest
      - These values can be found in the VPC that was set up by following the instructions in
      [Deploy a vpc using the VPC Terraform module](#task-deploy-a-vpc-using-the-vpc-terraform-module), eg:
      
        ```yaml
          network:
            vpc:
              id: vpc-01234567
              subnets:
                public:
                  - id: subnet-1234567
                  - id: subnet-2468012
                private:
                  - id: subnet-35791357
                  - id: subnet-4680246
        ```
      
      - Copy the certificate ARN from the AWS Console. The cert arn can be found by going to:
        - aws console, load balancers, select the load balancer that contains your {environment} name
        - go to “_Listeners and rules_” & select the listener that listens on _https:443_ , click the value for that listener under the “_Default SSL/TLS certificate_” header. This brings you to an AWS Certificate Manager page
        - copy the certificate ARN, eg: `arn:aws:acm:eu-west-2:1234567890:certificate/abc12345-1234-1234-12c3-01234567890ab`
        - `copilot/environments/<environment>/manifest.yml` add the certificate ARN here under the previously added code block
        
        ```yaml
        http:
          public:
            certificates:
              - arn:aws:acm:eu-west-2:1234567890:certificate/abc12345-1234-1234-12c3-01234567890ab
        ```
        
      - On the AWS Certificate Manager page you will also need to grab the “_Domain_” name, eg: `internal.<environment>.demodjango.uktrade.digital`
      - `copilot/web/manifest.yml`,  create a key that matches your {environment} name under the `environments` key following the pattern in the yml code example below. 
      - Under the `http` key, set `alias` to the domain name you just copied. 
      - On the AWS Load Balancers console page, copy the _Application Load Balancer ARN_ for your {environment} to the `alb` section of the code block, eg:
      
      ```yaml
      environments:
        <environment>:
          http:
            alb: arn:aws:elasticloadbalancing:eu-west-2:123456789012:loadbalancer/app/demodjango-<environment>/ab123a456b789cd
            alias: internal.<environment>.demodjango.uktrade.digital
      ```
  - `copilot/web/manifest.yml`, check that the REDIS_ENDPOINT is:
    `/copilot/${COPILOT_APPLICATION_NAME}/${COPILOT_ENVIRONMENT_NAME}/secrets/DEMODJANGO_REDIS_ENDPOINT`
    
    and not hardcoded to:
    
    `/copilot/${COPILOT_APPLICATION_NAME}-redis/${COPILOT_ENVIRONMENT_NAME}/secrets/WILLG_REDIS`
    
  - `copilot/web/addons/demodjango-s3-bucket.yml` kms key issue - we had to   manually add a `KmsAlias` under the `demodjangoKMSKeyConfigMap` module (There’s an open ticket to fix this step):
    ```
    demodjangoKMSKeyConfigMap:
      <environment>
        KmsAlias: 'alias/demodjango-<environment>-demodjangoS3Bucket-key'
    ```

  - Deploy environment
    - `copilot app init demodjango`
    - `copilot env init --name <environment> --profile $AWS_PROFILE --default-config`
    - `copilot env deploy --name <environment>`
    
  - If while deploying the environment you encounter the error: 
  ```
    Lookup override at copilot/environments/overrides: cdk.json does not exist under copilot/environments/overrides
  ``` 
  Solve by deleting the overrides directory as this doesn’t exist on the GitHub repo _terraform-deploy_ branch
        
  - Add the `DJANGO_SECRET_KEY` secret for you environment, ensure the secret value is in quotes: `copilot secret init --name DJANGO_SECRET_KEY --values <environment>='<something_random>'`
  
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
