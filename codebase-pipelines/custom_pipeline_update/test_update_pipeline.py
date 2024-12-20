import pytest
import unittest
from unittest.mock import MagicMock, patch

from update_pipeline import update_pipeline_stage_failure


class TestUpdatePipeline(unittest.TestCase):

    def test_update_pipeline_stage_failure_sets_rollback(self):
        with patch("boto3.client") as mock_boto_client:
            mock_client = MagicMock()
            mock_boto_client.return_value = mock_client

            mock_client.get_pipeline.return_value = {
                "pipeline": {
                    "name": "test-pipeline",
                    "stages": [
                        {
                            "name": "Deploy",
                        }
                    ]
                }
            }

            update_pipeline_stage_failure(["test-pipeline"])

            call_args = mock_client.update_pipeline.call_args[1]
            assert call_args["pipeline"]["stages"][0]["onFailure"]["result"] == "ROLLBACK"

    def test_update_pipeline_stage_failure_does_not_set_rollback(self):
        with patch("boto3.client") as mock_boto_client:
            mock_client = MagicMock()
            mock_boto_client.return_value = mock_client

            mock_client.get_pipeline.return_value = {
                "pipeline": {
                    "name": "test-pipeline",
                    "stages": [
                        {
                            "name": "Source",
                        }
                    ]
                }
            }

            with pytest.raises(ValueError) as error_msg:
                update_pipeline_stage_failure(["test-pipeline"])

            assert "Stage Deploy not found in pipeline test-pipeline" in str(error_msg.value)
