import json
import os
import boto3
import logging
import requests
import time
from typing import Tuple, Dict, Any, List

from botocore.exceptions import ClientError

logger = logging.getLogger()

logger.setLevel(logging.INFO)

class SecretRotator:
    def __init__(self, **kwargs):
        # Use provided values or default to environment variables
        self.waf_acl_name = kwargs.get('waf_acl_name', os.environ.get('WAFACLNAME'))
        self.waf_acl_id = kwargs.get('waf_acl_id', os.environ.get('WAFACLID'))
        self.waf_rule_priority = kwargs.get('waf_rule_priority', os.environ.get('WAFRULEPRI'))
        self.header_name = kwargs.get('header_name', os.environ.get('HEADERNAME'))
        self.application = kwargs.get('application', os.environ.get('APPLICATION'))
        self.environment = kwargs.get('environment', os.environ.get('ENVIRONMENT'))
        self.role_arn = kwargs.get('role_arn', os.environ.get('ROLEARN'))
        self.distro_list = kwargs.get('distro_list', os.environ.get('DISTROIDLIST'))

        
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
        
        client.update_web_acl(
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

    def get_cfdistro(self, distroid):
        client = self.get_cloudfront_session()
        response = client.get_distribution(
            Id=distroid
        )
        return response

    def get_cfdistro_config(self, distroid):
        client = self.get_cloudfront_session()
        response = client.get_distribution_config(
            Id=distroid
        )
        return response

    def update_cfdistro(self, distroid, headervalue):
        client = self.get_cloudfront_session()

        diststatus = self.get_cfdistro(distroid)
        if 'Deployed' in diststatus['Distribution']['Status']:
            distconfig = self.get_cfdistro_config(distroid)
            headercount = 0
            for k in distconfig['DistributionConfig']['Origins']['Items']:
                if k['CustomHeaders']['Quantity'] > 0:
                    for h in k['CustomHeaders']['Items']:
                        if self.header_name in h['HeaderName']:
                            logger.info("Update custom header, %s for origin, %s." % (h['HeaderName'], k['Id']))
                            headercount = headercount + 1
                            h['HeaderValue'] = headervalue
                        else:
                            logger.info("Ignore custom header, %s for origin, %s." % (h['HeaderName'], k['Id']))
                            pass
                else:
                    logger.info("No custom headers found in origin, %s." % k['Id'])
                    pass
            
            if headercount < 1:
                logger.error("No custom header, %s found in distribution Id, %s." % (self.header_name, distroid))
                raise ValueError("No custom header found in distribution Id, %s." % distroid)
            else:
                response = client.update_distribution(
                    Id=distroid,
                    IfMatch=distconfig['ResponseMetadata']['HTTPHeaders']['etag'],
                    DistributionConfig=distconfig['DistributionConfig']
                )
                
                return response
                
        else:
            logger.error("Distribution Id, %s status is not Deployed." % distroid)
            raise ValueError("Distribution Id, %s status is not Deployed." % distroid)

    def run_test_origin(self, url, secret):
        response = requests.get(
            url,
            headers={self.header_name: secret}
        )
        logger.info("Testing URL, %s - response code, %s " % (url, response.status_code))
        return response.status_code == 200
        
    def get_secrets(self, service_client, arn, token):
    # Obtain the pending secret value
        pending = service_client.get_secret_value(
            SecretId=arn,
            VersionId=token,
            VersionStage="AWSPENDING"
        )

        # Obtain metadata and find the current version
        metadata = service_client.describe_secret(SecretId=arn)
        current, currenttoken = None, None

        for version in metadata.get("VersionIdsToStages", {}):
            if "AWSCURRENT" in metadata["VersionIdsToStages"].get(version, []):
                currenttoken = version
                current = service_client.get_secret_value(
                    SecretId=arn,
                    VersionId=currenttoken,
                    VersionStage="AWSCURRENT"
                )
                logger.info("Getting current version %s for %s" % (version, arn))
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
            VersionStage="AWSCURRENT"
        )

        # Now try to get the secret version, if that fails, put a new secret
        try:
            service_client.get_secret_value(
                SecretId=arn,
                VersionId=token,
                VersionStage="AWSPENDING"
            )
            logger.info("createSecret: Successfully retrieved secret for %s." % arn)

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
            logger.info("createSecret: Successfully put secret for ARN %s and version %s." % (arn, token))

    def set_secret(self, service_client, arn, token):
        """Set the secret
        Updates the WAF ACL & the CloudFront distributions with the AWSPENDING & AWSCURRENT secret values.
        This method should set the AWSPENDING secret in the service that the secret belongs to. For example, if the secret is a database
        credential, this method should take the value of the AWSPENDING secret and set the user's password to this value in the database.
        Args:
            service_client (client): The secrets manager service client
            arn (string): The secret ARN or other identifier
            token (string): The ClientRequestToken associated with the secret version
        """
    # Confirm CloudFront distribution is in Deployed state
        matching_distributions = self.get_distro_list()
        logger.info("All distros: %s" % matching_distributions)
        for distro in matching_distributions:
            logger.info("Getting status of distro: %s" % distro['Id'])
            diststatus = self.get_cfdistro(distro['Id'])
            if 'Deployed' not in diststatus['Distribution']['Status']:
                logger.error("Distribution Id, %s status is not Deployed." % distro['Id'])
                raise ValueError("Distribution Id, %s status is not Deployed." % distro['Id'])

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

    def run_test_secret(self, service_client, arn, token):
        """Test the secret
        This method should validate that the AWSPENDING secret works in the service that the secret belongs to. For example, if the secret
        is a database credential, this method should validate that the user can login with the password in AWSPENDING and that the user has
        all of the expected permissions against the database.
        Args:
            service_client (client): The secrets manager service client
            arn (string): The secret ARN or other identifier
            token (string): The ClientRequestToken associated with the secret version
        """
        # This is where the secret should be tested against the service

        pendingsecret, currentsecret = self.get_secrets(service_client, arn, token)

        secrets = [pendingsecret['HEADERVALUE'], currentsecret['HEADERVALUE']]

        # Test all distributions with both secrets
        matching_distributions = self.get_distro_list()
        for distro in matching_distributions:
            try:
                for s in secrets:
                    if self.run_test_origin("http://" + distro['Origin'], s):
                        logger.info("Origin ok for http://%s" % distro['Origin'])
                        pass
                    else:
                        logger.error("Tests failed for URL, http://%s" % distro['Origin'])
                        raise ValueError("Tests failed for URL, http://%s" % distro['Origin'])
            except ClientError as e:
                logger.error('Error: {}'.format(e))

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
            if "AWSCURRENT" in metadata["VersionIdsToStages"][version]:
                if version == pending_version_token:
                    logger.info("finishSecret: Version %s already marked as AWSCURRENT for %s" % (version, arn))
                    return
                current_version_token = version
                break

        # Finalize by staging the secret version current
        service_client.update_secret_version_stage(
            SecretId=arn,
            VersionStage="AWSCURRENT",
            MoveToVersionId=pending_version_token,
            RemoveFromVersionId=current_version_token
        )
        logger.info("finishSecret: Successfully set AWSCURRENT stage to version %s for secret %s." % (pending_version_token, arn))

#======================================================================================================================
# Lambda entry point
#======================================================================================================================

def lambda_handler(event, context):
    logger.info("log -- Event: %s " % json.dumps(event))

    arn = event['SecretId']
    token = event['ClientRequestToken']
    step = event['Step']

    service_client = boto3.client('secretsmanager')

    # Make sure the version is staged correctly
    metadata = service_client.describe_secret(SecretId=arn)
    if not metadata['RotationEnabled']:
        logger.error("Secret %s is not enabled for rotation" % arn)
        raise ValueError("Secret %s is not enabled for rotation" % arn)
    
    versions = metadata['VersionIdsToStages']
    rotator = SecretRotator()  # Uses environment variables by default

    if token not in versions:
        logger.error("Secret version %s has no stage for rotation of secret %s." % (token, arn))
        raise ValueError("Secret version %s has no stage for rotation of secret %s." % (token, arn))
    if "AWSCURRENT" in versions[token]:
        logger.info("Secret version %s already set as AWSCURRENT for secret %s." % (token, arn))
        return
    elif "AWSPENDING" not in versions[token]:
        logger.error("Secret version %s not set as AWSPENDING for rotation of secret %s." % (token, arn))
        raise ValueError("Secret version %s not set as AWSPENDING for rotation of secret %s." % (token, arn))

    if step == "createSecret":
        rotator.create_secret(service_client, arn, token)
    elif step == "setSecret":
        rotator.set_secret(service_client, arn, token)
    elif step == "testSecret":
        rotator.run_test_secret(service_client, arn, token)
    elif step == "finishSecret":
        rotator.finish_secret(service_client, arn, token)
    else:
        raise ValueError("Invalid step parameter")
