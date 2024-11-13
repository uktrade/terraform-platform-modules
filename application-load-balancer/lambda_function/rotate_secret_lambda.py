import json
import boto3
import logging

from secret_rotator import SecretRotator

logger = logging.getLogger()
logger.setLevel(logging.INFO)

AWSPENDING="AWSPENDING"
AWSCURRENT="AWSCURRENT"


def lambda_handler(event, context):
    logger.info("log -- Event: %s " % json.dumps(event))

    arn = event['SecretId']
    token = event['ClientRequestToken']
    step = event['Step']
    test_domains = event.get('TestDomains', [])
    
    # logger.info(f"ARN - {arn}")
    # logger.info(f"TOKEN - {token}")
    # logger.info(f"STEP - {step}")
    # logger.info(f"TEST DOMAINS - {test_domains}")

    service_client = boto3.client('secretsmanager')

    # Make sure the version is staged correctly
    metadata = service_client.describe_secret(SecretId=arn)
    if not metadata['RotationEnabled']:
        logger.error("Secret is not enabled for rotation")
        raise ValueError("Secret is not enabled for rotation")
    
    versions = metadata['VersionIdsToStages']
    logger.info(f"VERSIONS: {versions}")
    logger.info(f"VERSIONS TOKEN: {versions[token]}")
    
    rotator = SecretRotator()

    if token not in versions:
        logger.error("Secret version %s has no stage for rotation of secret." % (token))
        raise ValueError("Secret version %s has no stage for rotation of secret." % (token))
    if AWSCURRENT in versions[token]:
        logger.info("Secret version %s already set as AWSCURRENT for secret." % (token))
    elif AWSPENDING not in versions[token]:
        logger.error("Secret version %s not set as AWSPENDING for rotation of secret." % (token))
        raise ValueError("Secret version %s not set as AWSPENDING for rotation of secret." % (token))
    
    if step == "createSecret":
        logger.info("Entered createSecret step")
        rotator.create_secret(service_client, arn, token)
    elif step == "setSecret":
        logger.info("Entered setSecret step")
        rotator.set_secret(service_client, arn, token)
    elif step == "testSecret":
        logger.info("Entered testSecret step")
        rotator.run_test_secret(service_client, arn, token, test_domains)
    elif step == "finishSecret":
        logger.info("Entered finishSecret step")
        rotator.finish_secret(service_client, arn, token)
    else:
        raise ValueError("Invalid step parameter")
