import json
import boto3
import logging

from secret_rotator import SecretRotator

logger = logging.getLogger()
logger.setLevel(logging.INFO)

AWSPENDING="AWSPENDING"
AWSCURRENT="AWSCURRENT"


def lambda_handler(event, context):
    logger.info(f"log -- Event: {json.dumps(event)}")

    service_client = boto3.client('secretsmanager')

    # Ensure version is staged correctly
    metadata = service_client.describe_secret(SecretId=event['SecretId'])
    if not metadata['RotationEnabled']:
        logger.error("Secret is not enabled for rotation")
        raise ValueError("Secret is not enabled for rotation")
    
    versions = metadata['VersionIdsToStages']
    logger.info(f"VERSIONS: {versions}")
    logger.info(f"VERSIONS TOKEN: {versions[event['ClientRequestToken']]}")

    if event['ClientRequestToken'] not in versions:
        logger.error(f"Secret version {event['ClientRequestToken']} has no stage for rotation of secret.")
        raise ValueError(f"Secret version {event['ClientRequestToken']} has no stage for rotation of secret.")
    if AWSCURRENT in versions[event['ClientRequestToken']]:
        logger.info(f"Secret version {event['ClientRequestToken']} already set as AWSCURRENT for secret.")
    elif AWSPENDING not in versions[event['ClientRequestToken']]:
        logger.error(f"Secret version {event['ClientRequestToken']} not set as AWSPENDING for rotation of secret.")
        raise ValueError(f"Secret version {event['ClientRequestToken']} not set as AWSPENDING for rotation of secret.")
    
    rotator = SecretRotator()
    step = event['Step']
    
    if step == "createSecret":
        logger.info("Entered createSecret step")
        rotator.create_secret(service_client, event['SecretId'], event['ClientRequestToken'])
    elif step == "setSecret":
        logger.info("Entered setSecret step")
        rotator.set_secret(service_client, event['SecretId'], event['ClientRequestToken'])
    elif step == "testSecret":
        logger.info("Entered testSecret step")
        rotator.run_test_secret(service_client, event['SecretId'], event['ClientRequestToken'], event.get('TestDomains', []))
    elif step == "finishSecret":
        logger.info("Entered finishSecret step")
        rotator.finish_secret(service_client, event['SecretId'], event['ClientRequestToken'])
    else:
        raise ValueError("Invalid step parameter")
