from unittest.mock import AsyncMock, MagicMock
import json


TEST_CLOUDRUN_HOSTNAME = "DEFAULT_TEST_CLOUDRUN"
TEST_CLOUDRUN_URL = f"https://{TEST_CLOUDRUN_HOSTNAME}"


class CloudrunClientFixture:
    tags: dict[str, list[str]]
    hostname: str = TEST_CLOUDRUN_HOSTNAME

    def __init__(self, mock_client: AsyncMock):
        self.client = mock_client
        self.tags = {}

        async def add_tag(service_name, revision_name, tag_string):
            key = f"{service_name},{revision_name}"
            if not key in self.tags:
                self.tags[key] = []
            self.tags[key].append(tag_string)
            return TEST_CLOUDRUN_URL

        self.client.tag_revision.side_effect = add_tag


class BucketDataFixture:
    def __init__(self, mock: MagicMock):
        self.mock = mock
        self.data: dict[str, str] = {}

        def get_blob(bucket: str, revision: str) -> str | None:
            return self.data[revision] if revision in self.data else None

        self.mock.side_effect = get_blob

    def given_metadata_exists_for(
        self,
        revision: str = "projects/DEFAULT/locations/DEFAULT/services/DEFAULT/revisions/DEFAULT",
        uri: str = "https://DEFAULT_URL",
        us_model_version: str = "DEFAULT.US.VERSION",
        uk_model_version: str = "DEFAULT.UK.VERSION",
    ):
        metadata = {
            "models": {"uk": us_model_version, "us": uk_model_version},
            "revision": revision,
            "uri": uri,
        }
        self.data[f"us.{us_model_version}.json"] = json.dumps(metadata)
        self.data[f"uk.{uk_model_version}.json"] = json.dumps(metadata)
