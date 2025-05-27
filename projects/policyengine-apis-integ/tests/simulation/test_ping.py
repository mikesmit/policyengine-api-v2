import policyengine_simulation_api_client
import pytest

@pytest.mark.asyncio
async def test_ping(async_client):
    response = await async_client.call(
        "ping_ping_post",
        policyengine_simulation_api_client.PingRequest(value=12)
    )
    assert response.incremented == 13