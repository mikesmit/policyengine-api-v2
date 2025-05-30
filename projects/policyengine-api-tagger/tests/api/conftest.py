from unittest.mock import AsyncMock, patch
import pytest
from .common import BucketDataFixture
from .common import CloudrunClientFixture


@pytest.fixture()
def bucket_data():
    with patch(
        "policyengine_api_tagger.api.revision_tagger._get_blob"
    ) as get_blob:
        mb = BucketDataFixture(get_blob)
        yield mb


@pytest.fixture()
def cloudrun():
    with patch(
        "policyengine_api_tagger.api.revision_tagger.CloudrunClient",
        return_value=AsyncMock(),
    ) as MockCloudrunClient:
        client = AsyncMock()
        MockCloudrunClient.return_value = client
        yield CloudrunClientFixture(client)
