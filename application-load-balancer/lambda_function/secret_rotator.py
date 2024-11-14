import json
import os
import boto3
import logging
import requests
import time
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
    
    def get_cloudfront_session(self) -> boto3.client:
        sts = boto3.client('sts')
        credentials = sts.assume_role(RoleArn=self.role_arn, RoleSessionName='rotation_session')["Credentials"]
        return boto3.client('cloudfront',
                            aws_access_key_id=credentials["AccessKeyId"],
                            aws_secret_access_key=credentials["SecretAccessKey"],
                            aws_session_token=credentials["SessionToken"])
        
    def get_distro_list(self) -> List[Dict[str, Any]]:
        client = self.get_cloudfront_session()
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
        logger.info("Matched cloudfront distributions: %s" % matching_distributions)           
        return matching_distributions

        
    def get_wafacl(self) -> Dict[str, Any]:
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
        
    def update_wafacl(self, new_secret: str, prev_secret: str) -> None:
        client = boto3.client('wafv2')
        waf_acl = self.get_wafacl()
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
        
    def get_cfdistro(self, distro_id: str) -> Dict:
        """
        Fetches the CloudFront distribution details.
        """
        client = self.get_cloudfront_session()
        return client.get_distribution(Id=distro_id)
        
        
    def get_cfdistro_config(self, distro_id: str) -> Dict:
        """
        Fetches the configuration of a CloudFront distribution.
        """
        client = self.get_cloudfront_session()
        return client.get_distribution_config(Id=distro_id)
        

    def update_cfdistro(self, distro_id: str, header_value: str) -> Dict:
        """
        Updates the custom headers for a CloudFront distribution.

        Args:
            distro_id (str): The ID of the CloudFront distribution.
            header_value (str): The header value to set for the custom header.
        """
        client = self.get_cloudfront_session()

        if not self.is_distribution_deployed(distro_id):
            logger.error("Distribution Id, %s status is not Deployed." % distro_id)
            raise ValueError(f"Distribution Id, {distro_id} status is not Deployed.")

        dist_config = self.get_cfdistro_config(distro_id)

        updated = self.update_custom_headers(dist_config, header_value)

        if not updated:
            logger.error("No custom header, %s found in distribution Id, %s." % (self.header_name, distro_id))
            raise ValueError(f"No custom header found in distribution Id, {distro_id}.")

        # Update the distribution
        return self.apply_distribution_update(client, distro_id, dist_config)

    def is_distribution_deployed(self, distro_id: str) -> bool:
        """
        Checks if the CloudFront distribution is deployed.

        """
        dist_status = self.get_cfdistro(distro_id)
        return 'Deployed' in dist_status['Distribution']['Status']

    def update_custom_headers(self, dist_config: Dict, header_value: str) -> bool:
        """
        Updates custom headers in the distribution config.
        """
        header_count = 0
        for k in dist_config['DistributionConfig']['Origins']['Items']:
            if k['CustomHeaders']['Quantity'] > 0:
                for h in k['CustomHeaders']['Items']:
                    if self.header_name in h['HeaderName']:
                        logger.info(f"Update custom header, {h['HeaderName']} for origin: {k['Id']}.")
                        header_count += 1
                        h['HeaderValue'] = header_value
                    else:
                        logger.info(f"Ignore custom header, {h['HeaderName']} for origin: {k['Id']}.")
            else:
                logger.info(f"No custom headers found in origin: {k['Id']}.")
        
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
                logger.info("CloudFront distribution %s updated successfully", distro_id)
            else:
                logger.warning("Failed to update CloudFront distribution %s. Status code: %d", distro_id, status_code)
            
            return response

        except Exception as e:
            logger.error("Error updating CloudFront distribution %s: %s", distro_id, str(e))
            raise
        
    def run_test_origin_access(self, url: str, secret: str) -> bool:
        try:
            response = requests.get(
                url,
                headers={self.header_name: secret}, timeout=(3, 5) # 3-second connection timeout, 5-second read timeout
            )
            logger.info("Testing URL, %s - response code, %s " % (url, response.status_code))
            return response.status_code == 200
        except RequestException as e:
            logger.error(f"Connection error for URL {url}: {str(e)}")
            return False

        
    def get_secrets(self, service_client, arn: str, token: str) -> Tuple[Dict, Dict]:
    # Obtain the pending secret value
        pending = service_client.get_secret_value(
            SecretId=arn,
            VersionId=token,
            VersionStage=AWSPENDING
        )

        # Obtain metadata and find the current version
        metadata = service_client.describe_secret(SecretId=arn)
        current, currenttoken = None, None

        for version in metadata.get("VersionIdsToStages", {}):
            if AWSCURRENT in metadata["VersionIdsToStages"].get(version, []):
                currenttoken = version
                current = service_client.get_secret_value(
                    SecretId=arn,
                    VersionId=currenttoken,
                    VersionStage=AWSCURRENT
                )
                logger.info("Getting current version: %s" % (version))
                break  # Found AWSCURRENT, exit loop

        if not current:
            raise ValueError("No AWSCURRENT version found")

        # Parse secrets from JSON format
        pendingsecret = json.loads(pending['SecretString'])
        currentsecret = json.loads(current['SecretString'])

        return pendingsecret, currentsecret

    def create_secret(self, service_client, arn, token):
        """Create the secret
        This method first checks for the existence of a current secret for the passed in token. If one does not exist, it will generate a
        new secret and put it with the passed in token.
        Args:
            service_client (client): The secrets manager service client
            arn (string): The secret ARN or other identifier
            token (string): The ClientRequestToken associated with the secret version
        Raises:
            ResourceNotFoundException: If the secret with the specified arn and stage does not exist
        """
        # Make sure the current secret exists
        service_client.get_secret_value(
            SecretId=arn,
            VersionStage=AWSCURRENT
        )

        # Now try to get the secret version, if that fails, put a new secret
        try:
            service_client.get_secret_value(
                SecretId=arn,
                VersionId=token,
                VersionStage=AWSPENDING
            )
            logger.info("createSecret: Successfully retrieved secret")

        except service_client.exceptions.ResourceNotFoundException:

            # Generate a random password
            passwd = service_client.get_random_password(
                ExcludePunctuation=True
            )
            service_client.put_secret_value(
                SecretId=arn,
                ClientRequestToken=token,
                SecretString='{\"HEADERVALUE\":\"%s\"}' % passwd['RandomPassword'],
                VersionStages=['AWSPENDING']
            )
            logger.info("createSecret: Successfully put secret for version %s" % (token))

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
        for distro in matching_distributions:
            logger.info("Getting status of distro: %s" % distro['Id'])

            if not self.is_distribution_deployed(distro['Id']):
                logger.error("Distribution Id, %s status is not Deployed." % distro['Id'])
                raise ValueError("Distribution Id, %s status is not Deployed." % distro['Id'])
            else:
                logger.info("Distro %s is deployed" % distro['Id'])

        # Use get_secrets to retrieve AWSPENDING and AWSCURRENT secrets
        pendingsecret, currentsecret = self.get_secrets(service_client, arn, token)

        # Update CloudFront custom header and regional WAF WebACL rule with AWSPENDING and AWSCURRENT
        try:
            # WAF only needs setting once.
            self.update_wafacl(pendingsecret['HEADERVALUE'], currentsecret['HEADERVALUE'])
            
            # Sleep for 75 seconds for regional WAF config propagation
            time.sleep(75)
            
            # Update each CloudFront distribution with the new pending secret header
            for distro in matching_distributions:
                logger.info("Updating %s" % distro['Id'])
                self.update_cfdistro(distro['Id'], pendingsecret['HEADERVALUE'])
                
        except ClientError as e:
            logger.error('Error: {}'.format(e))
            raise ValueError("Failed to update resources CloudFront Distro Id %s , WAF WebACL Id %s " % (distro['Id'], self.waf_acl_id))

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
                logger.info(f"Testing dummy distro: %s", test_domain)
                error_msg = f"Simulating test failure for domain: http://{test_domain}" 
                logger.error(error_msg) 
                test_failures.append({ 'domain': test_domain, 'error': error_msg, }) 

        else:
            pendingsecret, currentsecret = self.get_secrets(service_client, arn, token)
            secrets = [pendingsecret['HEADERVALUE'], currentsecret['HEADERVALUE']]
        
            distro_list = self.get_distro_list()
            for distro in distro_list:
                logger.info(f"Testing distro: %s", distro["Id"])
                try:
                    for s in secrets:
                        if self.run_test_origin_access("http://" + distro["Domain"], s):
                            logger.info("Domain ok for http://%s" % distro["Domain"])
                            pass
                        else:
                            error_msg = f"Tests failed for URL, http://{distro["Domain"]}"
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
                    print("CALLING SEND_TEST_FAILURES!!!!!")
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
                    logger.info("finishSecret: Version %s already marked as AWSCURRENT" % (version))
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
        logger.info("finishSecret: Successfully set AWSCURRENT stage to version %s" % (pending_version_token))
