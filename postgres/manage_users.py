import json
import boto3
import psycopg2
from botocore.exceptions import ClientError


def drop_user(cursor, username):
    cursor.execute(f"SELECT * FROM pg_catalog.pg_user WHERE usename = '{username}'")

    if cursor.fetchone() is not None:
        cursor.execute(f"DROP OWNED BY {username}")
        cursor.execute(f"DROP USER {username}")


def create_db_user(conn, cursor, username, password, permissions):
    drop_user(cursor, username)

    cursor.execute(f"CREATE USER {username} WITH ENCRYPTED PASSWORD '%s'" % password)
    cursor.execute(f"GRANT {username} to postgres;")
    cursor.execute(f"GRANT {', '.join(permissions)} ON ALL TABLES IN SCHEMA public TO {username};")
    cursor.execute(f"ALTER DEFAULT PRIVILEGES FOR USER application_user IN SCHEMA public GRANT {', '.join(permissions)} ON TABLES TO {username};")

    if 'INSERT' in permissions:
        cursor.execute(f"GRANT CREATE ON SCHEMA public TO {username};")

    conn.commit()


def create_or_update_user_secret(ssm, user_secret_name, user_secret_string, event):
    user_secret_description = event['SecretDescription']
    copilot_application = event['CopilotApplication']
    copilot_environment = event['CopilotEnvironment']

    user_secret = None

    try:
        user_secret = ssm.put_parameter(
            Name=user_secret_name,
            Description=user_secret_description,
            Value=json.dumps(user_secret_string),
            Tags=[
                {'Key': 'managed-by', 'Value': 'Terraform'},
                {'Key': 'copilot-application', 'Value': copilot_application},
                {'Key': 'copilot-environment', 'Value': copilot_environment},
            ],
            Type="SecureString",
        )
    except ClientError as error:
        if error.response["Error"]["Code"] == "ParameterAlreadyExists":
            user_secret = ssm.put_parameter(
                Name=user_secret_name,
                Description=user_secret_description,
                Value=json.dumps(user_secret_string),
                Overwrite=True,
            )

    return user_secret


def handler(event, context):
    print("REQUEST RECEIVED:\n" + json.dumps(event))

    db_master_user_secret_arn = event['MasterUserSecretArn']
    user_secret_name = event['SecretName']
    username = event['Username']
    user_permissions = event['Permissions']

    secrets_manager = boto3.client("secretsmanager")
    ssm = boto3.client("ssm")

    master_user = json.loads(secrets_manager.get_secret_value(SecretId=db_master_user_secret_arn)["SecretString"])

    user_password = secrets_manager.get_random_password(
        PasswordLength=16,
        ExcludeCharacters='[]{}()"@/\\;=?&`><:|#',
        ExcludePunctuation=True,
        IncludeSpace=False,
    )["RandomPassword"]

    user_secret_string = {
        "username": username,
        "password": user_password,
        "engine": event["DbEngine"],
        "port": event["DbPort"],
        "dbname": event["DbName"],
        "host": event["DbHost"],
        "dbInstanceIdentifier": event["dbInstanceIdentifier"]
    }

    conn = psycopg2.connect(
        dbname=event["DbName"],
        user=master_user["username"],
        password=master_user["password"],
        host=event["DbHost"],
        port=event["DbPort"]
    )

    cursor = conn.cursor()

    create_db_user(conn, cursor, username, user_password, user_permissions)
    create_or_update_user_secret(ssm, user_secret_name, user_secret_string, event)

    cursor.close()
    conn.close()
