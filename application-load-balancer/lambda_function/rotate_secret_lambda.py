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

def get_secret_metadata(secret_id):
    """
    Retrieve the version ID and staging labels of the secret.
    """
    try:
        response = service_client.describe_secret(SecretId=secret_id)
        versions = response.get("VersionIdsToStages", {})
        logger.info(f"Retrieved metadata for secret")
        return versions
    except service_client.exceptions.ResourceNotFoundException:
        logger.error(f"Secret not found.")
        raise
    except Exception as e:
        logger.error(f"Error fetching secret metadata for secret: {str(e)}")
        raise
        
def validate_and_get_token(event, secret_id):
    """
    Validate and retrieve the appropriate token for secret rotation.
    """
    is_secrets_manager_triggered = 'ClientRequestToken' in event
    
    try:
        versions = get_secret_metadata(secret_id)
    except Exception:
        logger.error("Failed to retrieve secret metadata")
        raise

    if not versions:
        logger.error("No versions found for secret.")
        raise ValueError("No versions found for secret.")

    # Handle Secrets Manager triggered rotation
    if is_secrets_manager_triggered:
        token = event.get('ClientRequestToken')
        if not token:
            logger.error("ClientRequestToken is missing.")
            raise ValueError("ClientRequestToken is required.")

        if token not in versions:
            logger.error(f"Secret version has no stage for rotation.")
            raise ValueError(f"Secret version has no stage for rotation.")

        # Validate token stages
        stages = versions[token]
        if "AWSCURRENT" in stages:
            logger.info(f"Secret version already set as AWSCURRENT for secret.")
        elif "AWSPENDING" not in stages:
            logger.error(f"Secret version not set as AWSPENDING for rotation.")
            raise ValueError(f"Secret version not set as AWSPENDING for rotation.")
        
        return token

    # Handle manual invocation - find AWSCURRENT token
    logger.info(f"Lambda invoked manually, finding AWSCURRENT version")
    for version, stages in versions.items():
        if "AWSCURRENT" in stages:
            return version

    logger.error("No AWSCURRENT version found for the secret.")
    raise ValueError("No AWSCURRENT version found for the secret.")


def lambda_handler(event, context):
    logger.info(f"Received Event: {json.dumps(event)}")

    secret_id = event.get('SecretId') or event.get('SECRETID')
    if not secret_id:
        logger.error("Unable to determine SecretId.")
        raise ValueError("Unable to determine SecretId.")

    token = validate_and_get_token(event, secret_id)

    rotator = SecretRotator()
    step = event.get('Step', None)

    if step:
        # If 'Step' exists, process the step from the event
        logger.info(f"Processing specific step: {step}")
        if step == "createSecret":
            logger.info("Entered createSecret step")
            rotator.create_secret(service_client, secret_id, token)
        elif step == "setSecret":
            logger.info("Entered setSecret step")
            rotator.set_secret(service_client, secret_id, token)
        elif step == "testSecret":
            logger.info("Entered testSecret step")
            rotator.run_test_secret(service_client, secret_id, token, event.get('TestDomains', []))
        elif step == "finishSecret":
            logger.info("Entered finishSecret step")
            rotator.finish_secret(service_client, secret_id, token)
        else:
            logger.error(f"Invalid step parameter: {step}")
            raise ValueError(f"Invalid step parameter: {step}")
    else:
        logger.info("Step not found in event. Processing all steps manually.")
        steps = ["createSecret", "setSecret", "testSecret", "finishSecret"]

        for step in steps:
            logger.info(f"Processing step: {step}")
            if step == "createSecret":
                logger.info("Entered createSecret step - manual invocation")
                rotator.create_secret(service_client, secret_id, token)
            elif step == "setSecret":
                logger.info("Entered setSecret step - manual invocation")
                rotator.set_secret(service_client, secret_id, token)
            elif step == "testSecret":
                logger.info("Entered testSecret step - manual invocation")
                rotator.run_test_secret(service_client, secret_id, token, event.get('TestDomains', []))
            elif step == "finishSecret":
                logger.info("Entered finishSecret step - manual invocation")
                rotator.finish_secret(service_client, secret_id, token)
            else:
                logger.error(f"Invalid step: {step}")
                raise ValueError(f"Invalid step: {step}")

