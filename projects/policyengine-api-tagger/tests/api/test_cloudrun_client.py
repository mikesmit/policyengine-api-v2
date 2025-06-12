from unittest.mock import AsyncMock, patch
import pytest
from policyengine_api_tagger.api.cloudrun_client import CloudrunClient
from google.cloud.run_v2 import (
    TrafficTarget,
    Service,
    TrafficTargetAllocationType,
    UpdateServiceRequest,
)


@pytest.mark.asyncio
@patch(
    "policyengine_api_tagger.api.cloudrun_client.ServicesAsyncClient",
    return_value=AsyncMock,
)
async def test_given_tagged_revision_exists__then_return_that_revision(
    ServicesAsyncClient,
):
    async_client = AsyncMock()
    ServicesAsyncClient.return_value = async_client

    service = AsyncMock()
    async_client.get_service.return_value = service
    service.uri = "https://TEST_SERVICE_URI"
    service.traffic = [
        TrafficTarget(revision="TEST_REVISION_NAME", percent=0, tag="TEST_TAG")
    ]

    client = CloudrunClient()
    result = await client.tag_revision(
        cloudrun_service_name="TEST_SERVICE_NAME",
        revision_name="TEST_REVISION_NAME",
        tag="TEST_TAG",
    )

    assert result == "https://TEST_SERVICE_URI"
    async_client.update_service.assert_not_called()


@pytest.mark.asyncio
@patch(
    "policyengine_api_tagger.api.cloudrun_client.ServicesAsyncClient",
    return_value=AsyncMock,
)
async def test_given_tagged_revision_DOES_NOT_exist__then_create_and_return_new_tag(
    ServicesAsyncClient,
):
    async_client = AsyncMock()
    ServicesAsyncClient.return_value = async_client

    service = Service()
    async_client.get_service.return_value = service
    service.uri = "https://TEST_SERVICE_URI"
    service.traffic = [
        TrafficTarget(
            revision="TEST_REVISION_NAME", percent=0, tag="SOME_OTHER_TAG"
        )
    ]

    client = CloudrunClient()
    result = await client.tag_revision(
        cloudrun_service_name="TEST_SERVICE_NAME",
        revision_name="TEST_REVISION_NAME",
        tag="TEST_TAG",
    )

    assert result == "https://TEST_SERVICE_URI"
    async_client.update_service.assert_called_once_with(
        UpdateServiceRequest(
            service=Service(
                uri="https://TEST_SERVICE_URI",
                traffic=[
                    TrafficTarget(
                        revision="TEST_REVISION_NAME",
                        percent=0,
                        tag="SOME_OTHER_TAG",
                    ),
                    TrafficTarget(
                        revision="TEST_REVISION_NAME",
                        percent=0,
                        tag="TEST_TAG",
                        type_=TrafficTargetAllocationType.TRAFFIC_TARGET_ALLOCATION_TYPE_REVISION,
                    ),
                ],
            ),
            update_mask={"paths": ["traffic"]},
        )
    )


@pytest.mark.asyncio
@patch(
    "policyengine_api_tagger.api.cloudrun_client.ServicesAsyncClient",
    return_value=AsyncMock,
)
async def test_given_tagged_revision_exists_on_different_revision__then_delete_old_tag_and_create_and_return_new_tag(
    ServicesAsyncClient,
):
    async_client = AsyncMock()
    ServicesAsyncClient.return_value = async_client

    service = Service()
    async_client.get_service.return_value = service
    service.uri = "https://TEST_SERVICE_URI"
    service.traffic = [
        TrafficTarget(
            revision="TEST_REVISION_NAME", percent=0, tag="SOME_OTHER_TAG"
        ),
        TrafficTarget(
            revision="OLD_REVISION", percent=0, tag="TEST_TAG"
        )
    ]

    client = CloudrunClient()
    result = await client.tag_revision(
        cloudrun_service_name="TEST_SERVICE_NAME",
        revision_name="TEST_REVISION_NAME",
        tag="TEST_TAG",
    )

    assert result == "https://TEST_SERVICE_URI"
    async_client.update_service.assert_called_once_with(
        UpdateServiceRequest(
            service=Service(
                uri="https://TEST_SERVICE_URI",
                traffic=[
                    TrafficTarget(
                        revision="TEST_REVISION_NAME",
                        percent=0,
                        tag="SOME_OTHER_TAG",
                    ),
                    TrafficTarget(
                        revision="TEST_REVISION_NAME",
                        percent=0,
                        tag="TEST_TAG",
                        type_=TrafficTargetAllocationType.TRAFFIC_TARGET_ALLOCATION_TYPE_REVISION,
                    ),
                ],
            ),
            update_mask={"paths": ["traffic"]},
        )
    )