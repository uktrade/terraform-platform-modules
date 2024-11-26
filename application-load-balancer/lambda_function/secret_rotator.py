import json
import os
import boto3
import logging
import requests
import time
import uuid
from typing import Tuple, Dict, Any, List, Optional
from slack_service import SlackNotificationService
from requests.exceptions import RequestException

from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

AWSPENDING="AWSPENDING"
AWSCURRENT="AWSCURRENT"


class SecretRotator:
    def __init__(self, **kwargs):
        # Use provided values or default to environment variables
        self.secret_id = kwargs.get('secret_id', os.environ.get('SECRETID'))
        self.waf_acl_name = kwargs.get('waf_acl_name', os.environ.get('WAFACLNAME'))
        self.waf_acl_id = kwargs.get('waf_acl_id', os.environ.get('WAFACLID'))
        waf_rule_priority = kwargs.get('waf_rule_priority', os.environ.get('WAFRULEPRI'))
        try:
            self.waf_rule_priority = int(waf_rule_priority)
        except (TypeError, ValueError):
            self.waf_rule_priority = 0
        self.header_name = kwargs.get('header_name', os.environ.get('HEADERNAME'))
        self.application = kwargs.get('application', os.environ.get('APPLICATION'))
        self.environment = kwargs.get('environment', os.environ.get('ENVIRONMENT'))
        self.role_arn = kwargs.get('role_arn', os.environ.get('ROLEARN'))
        self.distro_list = kwargs.get('distro_list', os.environ.get('DISTROIDLIST'))
        self.aws_account = kwargs.get('aws_account', os.environ.get('AWS_ACCOUNT'))
        
        slack_token = kwargs.get('slack_token', os.environ.get('SLACK_TOKEN'))
        slack_channel = kwargs.get('slack_channel', os.environ.get('SLACK_CHANNEL'))
        self.slack_service = None
        if slack_token and slack_channel:
            self.slack_service = SlackNotificationService(slack_token, slack_channel,  self.aws_account)

    def _get_aws_account_from_role_arn(self, role_arn: str) -> Optional[str]: 
        """ 
        Extracts and returns the AWS account ID from the RoleArn string. 
        """ 
        account_id = ""
        if role_arn: 
            try: 
                account_id = role_arn.split(":")[4] # Account ID is the 5th segment in an ARN, remember the double ::
                logger.info(f"Extracted Cloudfront AWS account ID: {account_id}")
                return account_id
            except IndexError: 
                logger.error(f"Invalid RoleArn format: '{role_arn}' - Unable to extract AWS account ID.") 
        else:
            logger.warning("No RoleArn provided - AWS account ID cannot be set.") 
            return None 
    
    def get_cloudfront_client(self) -> boto3.client:
        sts = boto3.client('sts')
        credentials = sts.assume_role(RoleArn=self.role_arn, RoleSessionName='rotation_session')["Credentials"]
        return boto3.client('cloudfront',
                            aws_access_key_id=credentials["AccessKeyId"],
                            aws_secret_access_key=credentials["SecretAccessKey"],
                            aws_session_token=credentials["SessionToken"])
        
    def get_distro_list(self) -> List[Dict[str, Any]]:
        client = self.get_cloudfront_client()
        paginator = client.get_paginator("list_distributions")
        matching_distributions = []

        for page in paginator.paginate():
            for distribution in page.get("DistributionList", {}).get("Items", []):
                aliases = distribution.get("Aliases", {}).get("Items", [])
                if any(domain in aliases for domain in self.distro_list.split(",")):
                    matching_distributions.append({
                        "Id": distribution["Id"],
                        "Origin": distribution['Origins']['Items'][0]['DomainName'],
                        "Domain": distribution['Aliases']['Items'][0]
                    })
        logger.info(f"Matched cloudfront distributions: {matching_distributions}")           
        return matching_distributions

        
    def get_waf_acl(self) -> Dict[str, Any]:
        client = boto3.client('wafv2')
        return client.get_web_acl(Name=self.waf_acl_name, Scope='REGIONAL', Id=self.waf_acl_id)

    
    def _create_byte_match_statement(self, search_string: str) -> Dict[str, Any]:
        return {
            'ByteMatchStatement': {
                'FieldToMatch': {'SingleHeader': {'Name': self.header_name}},
                'PositionalConstraint': 'EXACTLY',
                'SearchString': search_string,
                'TextTransformations': [{'Type': 'NONE', 'Priority': 0}]
            }
        }
        
    def update_waf_acl(self, new_secret: str, prev_secret: str) -> None:
        client = boto3.client('wafv2')
        waf_acl = self.get_waf_acl()
        lock_token = waf_acl['LockToken']
        metric_name = f"{self.application}-{self.environment}-XOriginVerify"
        rule = {
            'Name': f"{self.application}{self.environment}XOriginVerify",
            'Priority': self.waf_rule_priority,
            'Action': {'Allow': {}},
            'VisibilityConfig': {
                'SampledRequestsEnabled': True,
                'CloudWatchMetricsEnabled': True,
                'MetricName': metric_name
            },
            'Statement': {
                'OrStatement': {
                    'Statements': [
                        self._create_byte_match_statement(new_secret),
                        self._create_byte_match_statement(prev_secret)
                    ]
                }
            }
        }

        new_rules = [rule] + [r for r in waf_acl['WebACL']['Rules'] if r['Priority'] != self.waf_rule_priority]
        logger.info("Updating WAF WebACL with new rules.")
        
        response = client.update_web_acl(
            Name=self.waf_acl_name,
            Scope='REGIONAL',
            Id=self.waf_acl_id,
            LockToken=lock_token,
            DefaultAction={'Block': {}},
            Description='CloudFront Origin Verify',
            VisibilityConfig={
                'SampledRequestsEnabled': True,
                'CloudWatchMetricsEnabled': True,
                'MetricName': metric_name
            },
            Rules=new_rules
        )
        
        if response['ResponseMetadata']['HTTPStatusCode'] == 200:
            logger.info("WAF WebACL rules updated")
        
    def get_cf_distro(self, distro_id: str) -> Dict:
        """
        Fetches the CloudFront distribution details.
        """
        client = self.get_cloudfront_client()
        return client.get_distribution(Id=distro_id)
        
        
    def get_cf_distro_config(self, distro_id: str) -> Dict:
        """
        Fetches the configuration of a CloudFront distribution.
        """
        client = self.get_cloudfront_client()
        return client.get_distribution_config(Id=distro_id)
        

    def update_cf_distro(self, distro_id: str, header_value: str) -> Dict:
        """
        Updates the custom headers for a CloudFront distribution.

        Args:
            distro_id (str): The ID of the CloudFront distribution.
            header_value (str): The header value to set for the custom header.
        """
        client = self.get_cloudfront_client()

        if not self.is_distribution_deployed(distro_id):
            logger.error(f"Distribution Id: {distro_id} status is not Deployed.")
            raise ValueError(f"Distribution Id: {distro_id} status is not Deployed.")

        dist_config = self.get_cf_distro_config(distro_id)

        self.update_custom_headers(dist_config, header_value)

        # Update the distribution 
        try: 
            return self.apply_distribution_update(client, distro_id, dist_config) 
            
        except RuntimeError as e: 
            logger.error(f"Failed to update custom headers for distribution Id {distro_id}: {e}") 
            raise


    def is_distribution_deployed(self, distro_id: str) -> bool:
        """
        Checks if the CloudFront distribution is deployed.

        """
        dist_status = self.get_cf_distro(distro_id)
        return 'Deployed' in dist_status['Distribution']['Status']
    
    def update_custom_headers(self, dist_config: Dict, header_value: str) -> bool:
        """
        Updates or creates custom headers in the distribution config.
        Returns True if any headers were updated or created.
        """
        header_count = 0
        
        for origin in dist_config['DistributionConfig']['Origins']['Items']:
            if 'CustomHeaders' not in origin or origin['CustomHeaders']['Quantity'] == 0:
                logger.info(f"No custom headers exist. Creating new custom header {self.header_name} for origin: {origin['Id']}")
                origin['CustomHeaders'] = {
                    'Quantity': 1,
                    'Items': [{
                        'HeaderName': self.header_name,
                        'HeaderValue': header_value
                    }]
                }
                header_count += 1
                continue
                
            found_header = False
            for header in origin['CustomHeaders']['Items']:
                if header['HeaderName'] == self.header_name:
                    logger.info(f"Updating existing custom header {self.header_name} for origin: {origin['Id']}")
                    header['HeaderValue'] = header_value
                    found_header = True
                    header_count += 1
                    break
                      
            if not found_header:
                logger.info(f"Adding new custom header {self.header_name} to existing headers for origin: {origin['Id']}")
                origin['CustomHeaders']['Items'].append({
                    'HeaderName': self.header_name,
                    'HeaderValue': header_value
                })
                origin['CustomHeaders']['Quantity'] += 1
                header_count += 1
                
        return header_count > 0

            
    def apply_distribution_update(self, client, distro_id: str, dist_config: Dict) -> Dict:
        """
        Applies the distribution update to CloudFront.
        """
        try:
            response = client.update_distribution(
                Id=distro_id,
                IfMatch=dist_config['ResponseMetadata']['HTTPHeaders']['etag'],
                DistributionConfig=dist_config['DistributionConfig']
            )
            
            status_code = response['ResponseMetadata']['HTTPStatusCode']
            
            if status_code == 200:
                logger.info(f"CloudFront distribution {distro_id} updated successfully")
            else:
                logger.warning(f"Failed to update CloudFront distribution {distro_id}. Status code: {status_code}")
                raise RuntimeError(f"Failed to update CloudFront distribution {distro_id}. Status code: {status_code}")
            
            return response

        except Exception as e:
            logger.error(f"Error updating CloudFront distribution {distro_id}: {str(e)}")
            raise
        
    def run_test_origin_access(self, url: str, secret: str) -> bool:
        try:
            response = requests.get(
                url,
                headers={self.header_name: secret}, timeout=(3, 5) # 3-second connection timeout, 5-second read timeout
            )
            logger.info(f"Testing URL, {url} - response code, {response.status_code}")
            return response.status_code == 200
        except RequestException as e:
            logger.error(f"Connection error for URL {url}: {str(e)}")
            return False

        
    def get_secrets(self, service_client, arn: str, token: str) -> Tuple[Dict, Dict]:
        metadata = service_client.describe_secret(SecretId=arn)
        version_stages = metadata.get("VersionIdsToStages", {})
        current_version = None
        pending_version = None
        
        for version, stages in version_stages.items():
            if AWSCURRENT in stages:
                current_version = version
                logger.info(f"Found AWSCURRENT version: {version}")
            if AWSPENDING in stages:
                pending_version = version
                logger.info(f"Found AWSPENDING version: {version}")
        
        if not current_version:
            raise ValueError("No AWSCURRENT version found")
            
        if not pending_version:
            raise ValueError("No AWSPENDING version found")
        
        try:
            current = service_client.get_secret_value(
                SecretId=arn,
                VersionId=current_version,
                VersionStage=AWSCURRENT
            )
            
            pending = service_client.get_secret_value(
                SecretId=arn,
                VersionId=pending_version,
                VersionStage=AWSPENDING
            )
        except service_client.exceptions.ResourceNotFoundException as e:
            logger.error(f"Failed to retrieve secret values: {e}")
            raise
            
        # Parse secrets from JSON format
        pending_secret = json.loads(pending['SecretString'])
        current_secret = json.loads(current['SecretString'])
        
        return pending_secret, current_secret

        
        
        
    def create_secret(self, service_client, arn, token):
        """Create the secret.
        This method first checks for the existence of a current secret for the passed-in token. Irrespective of whether AWSPENDING
        exists or not, it will generate and create a new AWSPENDING secret with a random value.
        Args:
            service_client (client): The secrets manager service client
            arn (string): The secret ARN or other identifier
            token (string): The ClientRequestToken associated with the secret version
        Raises:
            ResourceNotFoundException: If the secret with the specified arn and stage does not exist
        """
        try:
            service_client.get_secret_value(
                SecretId=arn,
                VersionStage="AWSCURRENT"
            )
        except service_client.exceptions.ResourceNotFoundException:
            logger.error(f"AWSCURRENT version does not exist for secret")
            raise

        passwd = service_client.get_random_password(
            ExcludePunctuation=True
        )
        
        pending_token = str(uuid.uuid4())

        try:
            service_client.put_secret_value(
                SecretId=arn,
                ClientRequestToken=pending_token,
                SecretString='{\"HEADERVALUE\":\"%s\"}' % passwd['RandomPassword'],
                VersionStages=['AWSPENDING']
            )
            logger.info(f"Successfully created or overwritten AWSPENDING version for secret with token {token}")
        except Exception as e:
            logger.error(f"Failed to create AWSPENDING version for secret: {str(e)}")
            raise

    def set_secret(self, service_client, arn, token):
        """Set the secret
        Updates the WAF ACL & the CloudFront distributions with the AWSPENDING & AWSCURRENT secret values.
        This method should set the AWSPENDING secret in the service that the secret belongs to. 
        Args:
            service_client (client): The secrets manager service client
            arn (string): The secret ARN or other identifier
            token (string): The ClientRequestToken associated with the secret version
        """
    # Confirm CloudFront distribution is in Deployed state
        matching_distributions = self.get_distro_list()
        
        if not matching_distributions:
            logger.error("No matching distributions found. Cannot update Cloudfront distributions or WAF ACLs")
            raise ValueError("No matching distributions found. Cannot update Cloudfront distributions or WAF ACLs")
        
        for distro in matching_distributions:
            logger.info(f"Getting status of distro: {distro['Id']}")

            if not self.is_distribution_deployed(distro['Id']):
                logger.error(f"Distribution Id, {distro['Id']} status is not Deployed.")
                raise ValueError(f"Distribution Id, {distro['Id']} status is not Deployed.")
            else:
                logger.info(f"Distro {distro['Id']} is deployed")

        # Use get_secrets to retrieve AWSPENDING and AWSCURRENT secrets
        pendingsecret, currentsecret = self.get_secrets(service_client, arn, token)

        # Update regional WAF WebACL rule and CloudFront custom header with AWSPENDING and AWSCURRENT
        try:
            # WAF only needs setting once.
            self.update_waf_acl(pendingsecret['HEADERVALUE'], currentsecret['HEADERVALUE'])
            
            # Sleep for 75 seconds for regional WAF config propagation
            time.sleep(75)
            
            # Update each CloudFront distribution with the new pending secret header
            for distro in matching_distributions:
                logger.info(f"Updating {distro['Id']}")
                self.update_cf_distro(distro['Id'], pendingsecret['HEADERVALUE'])
                
        except ClientError as e:
            logger.error(f"Error updating resources: {e}")
            raise ValueError(
                f"Failed to update resources CloudFront Distro Id {distro['Id']} , WAF WebACL Id {self.waf_acl_id}") from e


    def run_test_secret(self, service_client, arn, token, test_domains=[]):
        """Test the secret
        This method validates that the AWSPENDING secret works in the service.
        If any tests fail:
        1. Attempts to send a Slack notification (notification failure won't stop the rotation process)
        2. If Lambda event contains key TestDomains and provided domains to test, then you can trigger a Slack notification to the configured Slack channel
        """
        test_failures = []
        
        # Check for TestDomains key in the Lambda event 
        if test_domains: 
            logger.info(f"TestDomains key exists in Lambda event - testing provided dummy domains only")
            for test_domain in test_domains:
                logger.info(f"Testing dummy distro: {test_domain}")
                error_msg = f"Simulating test failure for domain: http://{test_domain}" 
                logger.error(error_msg) 
                test_failures.append({ 'domain': test_domain, 'error': error_msg, }) 

        else:
            pendingsecret, currentsecret = self.get_secrets(service_client, arn, token)
            secrets = [pendingsecret['HEADERVALUE'], currentsecret['HEADERVALUE']]
        
            distro_list = self.get_distro_list()
            for distro in distro_list:
                logger.info(f"Testing distro: {distro['Id']}")
                try:
                    for s in secrets:
                        if self.run_test_origin_access("http://" + distro["Domain"], s):
                            logger.info(f"Domain ok for http://{distro['Domain']}")
                            pass
                        else:
                            error_msg = f"Tests failed for URL, http://{distro['Domain']}"
                            logger.error(error_msg)
                            test_failures.append({
                                'domain': distro["Domain"],
                                'secret_type': 'PENDING' if s == pendingsecret['HEADERVALUE'] else 'CURRENT',
                                'error': 'Connection failed or non-200 response'
                            })
                except Exception as e:
                    error_msg = f"Error testing {distro}: {str(e)}"
                    logger.error(error_msg)
                    test_failures.append({
                        'domain': distro["Domain"],
                        'error': str(e)
                    })

        if test_failures:
            if self.slack_service:
                try:
                    self.slack_service.send_test_failures(
                        failures=test_failures,
                        environment=self.environment,
                        application=self.application
                    )
                except Exception as e:
                        logger.error(f"Failure to send Slack notification{str(e)}")


    def finish_secret(self, service_client, arn, pending_version_token):
        """Finish the secret
        This method finalizes the rotation process by marking the secret version passed in as the AWSCURRENT secret.
        Args:
            service_client (client): The secrets manager service client
            arn (string): The secret ARN or other identifier
            token (string): The ClientRequestToken associated with the secret version
        Raises:
            ResourceNotFoundException: If the secret with the specified arn does not exist
        """

        # First describe the secret to get the current version
        metadata = service_client.describe_secret(SecretId=arn)
        current_version_token = None
        for version in metadata["VersionIdsToStages"]:
            if AWSCURRENT in metadata["VersionIdsToStages"][version]:
                if version == pending_version_token:
                    logger.info(f"finishSecret: Version {version} already marked as AWSCURRENT")
                    return
                current_version_token = version
                break

        # Finalize by staging the secret version current
        service_client.update_secret_version_stage(
            SecretId=arn,
            VersionStage=AWSCURRENT,
            MoveToVersionId=pending_version_token,
            RemoveFromVersionId=current_version_token
        )
        logger.info(f"finishSecret: Successfully set AWSCURRENT stage to version {pending_version_token}")
