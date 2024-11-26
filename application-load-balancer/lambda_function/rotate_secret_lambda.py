import os
import json
import boto3
import logging

from secret_rotator import SecretRotator

logger = logging.getLogger()
logger.setLevel(logging.INFO)

service_client = boto3.client('secretsmanager')

AWSPENDING="AWSPENDING"
AWSCURRENT="AWSCURRENT"


def lambda_handler(event, context):
    # Event can be emitted either from AWS Secrets Manager when secret is rotating OR when lambda invoke resource in application-load-balancer module is re-provisioned. If the latter then the event object structure matches what is passed into the lambda invoke resource
    logger.info(f"Received Event: {json.dumps(event)}")
 
    # Secret ID name will be different depending on event source
    secret_id = event.get('SecretId') or event.get('SECRETID')
    if not secret_id:
        logger.error("Unable to determine SecretId.")
        raise ValueError("Unable to determine SecretId.")
    
    token = "" #todo Remove token argument for rotation steps functions, create, set, test, finish
    rotator = SecretRotator()
    
    step = event.get('Step', None)
    pending_version_token = event.get('ClientRequestToken', None)
    
    # If Lambda triggered by AWS Secrets Manager, event will have 'Step' & 'ClientRequestToken' properties
    if step and pending_version_token:
        logger.info(f"Processing specific step: {step}")
        if step == "createSecret":
            logger.info("Entered createSecret step")
            rotator.create_secret(service_client, secret_id)
        elif step == "setSecret":
            logger.info("Entered setSecret step")
            rotator.set_secret(service_client, secret_id)
        elif step == "testSecret":
            logger.info("Entered testSecret step")
            rotator.run_test_secret(service_client, secret_id, event.get('TestDomains', []))
        elif step == "finishSecret":
            logger.info("Entered finishSecret step")
            rotator.finish_secret(service_client, secret_id, pending_version_token)
        else:
            logger.error(f"Invalid step parameter: {step}")
            raise ValueError(f"Invalid step parameter: {step}")
    else:
        logger.info("Step not found in event. Processing all steps manually.")
        steps = ["createSecret", "setSecret", "testSecret", "finishSecret"]

        for step in steps:
            logger.info(f"Processing step: {step} - manual invocation")
            if step == "createSecret":
                pending_version_token = rotator.create_secret(service_client, secret_id)
            elif step == "setSecret":
                rotator.set_secret(service_client, secret_id)
            elif step == "testSecret":
                rotator.run_test_secret(service_client, secret_id, event.get('TestDomains', []))
            elif step == "finishSecret":
                rotator.finish_secret(service_client, secret_id, pending_version_token)
            else:
                logger.error(f"Invalid step: {step}")
                raise ValueError(f"Invalid step: {step}")

