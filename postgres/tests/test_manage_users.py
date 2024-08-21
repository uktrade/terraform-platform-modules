import json
import boto3
import pytest
import unittest

from unittest.mock import MagicMock
from unittest.mock import patch
from moto import mock_aws

from postgres.manage_users import create_or_update_db_user, create_or_update_user_secret, handler

# if sys.version_info != (3, 11):
#     pytest.skip("Lambda uses 3.11 at runtime", allow_module_level=True)


class TestAppUserCustomResource(unittest.TestCase):
    def setUp(self):
        self.cursor = MagicMock()


    @classmethod
    def setUpClass(cls):
        cls.secret_name = "test-secret-name"
        cls.secret_string = '{"engine": "postgres", "port": 5432, "dbname": "main", "host": "test-host", "username": "random-user", "password": "password123"}'
        cls.event = {
            "SecretName": cls.secret_name,
            "SecretDescription": "used for testing",
            "Username": "test-user",
            "Permissions": ["SELECT"],
            "CopilotApplication": "test-app",
            "CopilotEnvironment": "test",
            "LogicalResourceId": "123LogicalResourceId",
            "StackId": "123/TestStackId",
            "ResponseURL": "https://test.url",
            "RequestId": "test-id-123",
        }
        cls.context = MagicMock()
        cls.context.log_stream_name = "test-log-stream"
        cls.conn = MagicMock()
        cls.cursor = MagicMock()


    @pytest.fixture(autouse=True)
    def capsys(self, capsys):
        self.capsys = capsys


    def test_create_or_update_db_user(self):
        self.cursor.fetchone.return_value = None
        conn = MagicMock()
        username = "test_user"
        password = "test_password"
        permissions = ["SELECT", "INSERT"]

        create_or_update_db_user(conn, self.cursor, username, password, permissions)

        self.cursor.execute.assert_any_call(
            f"CREATE USER {username} WITH ENCRYPTED PASSWORD '{password}'"
        )
        self.cursor.execute.assert_any_call(f"GRANT {username} to postgres;")
        self.cursor.execute.assert_any_call(
            f"GRANT {', '.join(permissions)} ON ALL TABLES IN SCHEMA public TO {username};"
        )
        self.cursor.execute.assert_any_call(
            f"ALTER DEFAULT PRIVILEGES FOR USER application_user IN SCHEMA public GRANT {', '.join(permissions)} ON TABLES TO {username};"
        )

        conn.commit.assert_called_once()

        
    def test_create_or_update_db_user_when_user_exists(self):
        self.cursor.fetchone.return_value = ["test_user"]
        conn = MagicMock()
        username = "test_user"
        password = "test_password"
        permissions = ["SELECT", "INSERT"]

        create_or_update_db_user(conn, self.cursor, username, password, permissions)

        self.cursor.execute.assert_any_call(
            f"ALTER USER {username} WITH ENCRYPTED PASSWORD '{password}'"
        )

        conn.commit.assert_called_once()
        

    @mock_aws
    def test_create_or_update_user_secret(self):
        ssm = boto3.client("ssm")
        user_secret_name = "/test/secret"
        user_secret_string = {"username": "test_user", "password": "test_password"}
        
        response = create_or_update_user_secret(
            ssm, user_secret_name, user_secret_string, self.event
        )
        parameter = ssm.get_parameter(Name=user_secret_name, WithDecryption=True)["Parameter"]
        parameter_described = ssm.describe_parameters()["Parameters"][0]

        assert response["Version"] == 1
        assert response["ResponseMetadata"]["HTTPStatusCode"] == 200
        assert parameter["Name"] == user_secret_name
        assert parameter["Value"] == json.dumps(user_secret_string)
        assert parameter_described["Description"] == "used for testing"


    @mock_aws
    def test_create_or_update_user_secret_overwrites(self):
        ssm = boto3.client("ssm")
        user_secret_name = "/test/secret"
        user_secret_string = {"username": "test_user", "password": "test_password"}
        ssm.put_parameter(Name=user_secret_name, Value="blah", Type="String")

        create_or_update_user_secret(ssm, user_secret_name, user_secret_string, self.event)

        parameter = ssm.get_parameter(Name=user_secret_name)["Parameter"]

        assert parameter["Version"] == 2
        assert parameter["Value"] == json.dumps(user_secret_string)

    # @patch("urllib.request.urlopen", return_value=None)
    # def test_send(self, urlopen):
    #     test_url = "https://test.url"
    #     event = {"ResponseURL": test_url}
    #     body = {"some": "test data"}
    #     logger = logging.getLogger(app_user.__name__)
    #     headers = {"Test": "header"}

    #     send(event, body, logger, headers)

    #     sent_request = urlopen.call_args_list[0].args[0]
    #     urlopen.assert_called_once()
    #     assert sent_request.headers == headers
    #     assert sent_request.full_url == "https://test.url"
    #     assert sent_request.data == body
    #     assert sent_request.get_method() == "PUT"

    # @patch("time.sleep", return_value=None)
    # @patch(
    #     "urllib.request.urlopen",
    #     side_effect=HTTPError("https://example.com", 404, "Not Found", None, BytesIO(b"Some Data")),
    # )
    # def test_send_failure_retries_5_times(self, urlopen, sleep):
    #     logger = logging.getLogger(app_user.__name__)
    #     logger.warning = MagicMock(logger.warning)
    #     logger.error = MagicMock(logger.error)

    #     event = {"ResponseURL": "https://test.url"}

    #     send(event, {}, logger, {})

    #     self.assertEqual(5, urlopen.call_count)
    #     logger.warning.assert_has_calls(
    #         [
    #             call("HTTP Error 404: Not Found [https://example.com] - Retry 1"),
    #             call("HTTP Error 404: Not Found [https://example.com] - Retry 2"),
    #             call("HTTP Error 404: Not Found [https://example.com] - Retry 3"),
    #             call("HTTP Error 404: Not Found [https://example.com] - Retry 4"),
    #         ]
    #     )
    #     logger.error.assert_called_with("HTTP Error 404: Not Found [https://example.com]")
    #     sleep.assert_has_calls(
    #         [
    #             call(5),
    #             call(10),
    #             call(15),
    #             call(20),
    #         ]
    #     )

    # @parameterized.expand(["Create", "Update"])
    # @patch("dbt_platform_helper.custom_resources.app_user.create_db_user")
    # @patch("dbt_platform_helper.custom_resources.app_user.send_response")
    # @patch("dbt_platform_helper.custom_resources.app_user.psycopg2.connect")
    # @mock_aws
    # def test_handler(self, request_type, mock_connect, mock_send_response, mock_create_db_user):
    #     secretsmanager = boto3.client("secretsmanager")
    #     secret_id = secretsmanager.create_secret(
    #         Name=self.secret_name, SecretString=self.secret_string
    #     )["ARN"]
    #     self.event["MasterUserSecret"] = secret_id
    #     self.event["RequestType"] = request_type
    #     mock_connect.return_value = self.conn
    #     self.conn.cursor = self.cursor

    #     handler(self.event, self.context)

    #     ssm = boto3.client("ssm")
    #     user_password = json.loads(ssm.get_parameter(Name=self.secret_name)["Parameter"]["Value"])[
    #         "password"
    #     ]
    #     mock_create_db_user.assert_called_once_with(
    #         self.conn, self.cursor(), "test-user", user_password, ["SELECT"]
    #     )

    #     captured = self.capsys.readouterr()
    #     data = json.loads(captured.out.split("\n")[2])["Data"]

    #     mock_send_response.assert_called_once_with(
    #         self.event, self.context, "SUCCESS", data, self.event["LogicalResourceId"]
    #     )

    # @patch("database.manage_users.drop_user")
    # @patch("database.manage_users.send_response")
    # @patch("database.manage_users.psycopg2.connect")
    # @mock_aws
    # def test_handler_delete(self, mock_connect, mock_send_response, mock_drop_user):
    #     secretsmanager = boto3.client("secretsmanager")
    #     secret_id = secretsmanager.create_secret(
    #         Name=self.secret_name, SecretString=self.secret_string
    #     )["ARN"]
    #     ssm = boto3.client("ssm")
    #     ssm.put_parameter(Name=self.secret_name, Value="blah", Type="String")
    #     self.event["MasterUserSecret"] = secret_id
    #     self.event["RequestType"] = "Delete"
    #     mock_connect.return_value = self.conn
    #     self.conn.cursor = self.cursor

    #     handler(self.event, self.context)

    #     captured = self.capsys.readouterr()
    #     data = json.loads(captured.out.split("\n")[2])["Data"]

    #     mock_drop_user.assert_called_once_with(self.cursor(), "test-user")
    #     mock_send_response.assert_called_once_with(
    #         self.event, self.context, "SUCCESS", data, self.event["LogicalResourceId"]
    #     )
    #     assert len(ssm.describe_parameters()["Parameters"]) == 0

    # @patch("dbt_platform_helper.custom_resources.app_user.send_response")
    # @patch("dbt_platform_helper.custom_resources.app_user.psycopg2.connect")
    # @mock_aws
    # def test_handler_invalid_request_type(self, mock_connect, mock_send_response):
    #     secretsmanager = boto3.client("secretsmanager")
    #     secret_id = secretsmanager.create_secret(
    #         Name=self.secret_name, SecretString=self.secret_string
    #     )["ARN"]
    #     self.event["MasterUserSecret"] = secret_id
    #     self.event["RequestType"] = "Patch"
    #     mock_connect.return_value = self.conn
    #     self.conn.cursor = self.cursor

    #     handler(self.event, self.context)

    #     captured = self.capsys.readouterr()
    #     data = json.loads(captured.out.split("\n")[2])["Data"]

    #     mock_send_response.assert_called_once_with(
    #         self.event, self.context, "FAILED", data, self.event["LogicalResourceId"]
    #     )

    # @patch("dbt_platform_helper.custom_resources.app_user.create_db_user", side_effect=Exception())
    # @patch("dbt_platform_helper.custom_resources.app_user.send_response")
    # @patch("dbt_platform_helper.custom_resources.app_user.psycopg2.connect")
    # @mock_aws
    # def test_handler_exception(self, mock_connect, mock_send_response, mock_create_db_user):
    #     secretsmanager = boto3.client("secretsmanager")
    #     secret_id = secretsmanager.create_secret(
    #         Name=self.secret_name, SecretString=self.secret_string
    #     )["ARN"]
    #     self.event["MasterUserSecret"] = secret_id
    #     self.event["RequestType"] = "Create"
    #     mock_connect.return_value = self.conn
    #     self.conn.cursor = self.cursor

    #     handler(self.event, self.context)

    #     captured = self.capsys.readouterr()
    #     data = json.loads(captured.out.split("\n")[2])["Data"]

    #     mock_send_response.assert_called_once_with(
    #         self.event, self.context, "FAILED", data, self.event["LogicalResourceId"]
    #     )