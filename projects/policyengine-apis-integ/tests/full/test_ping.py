import policyengine_full_api_client
import pytest

# I don't love this client. We should investigate alternatives.
# the package structure is really tedious to use
# it doesn't define methods on the client so it's not very OO
# and it returns a union instead of just throwing an exception
@pytest.mark.asyncio
async def test_ping(async_client):
    response = await async_client.call(
        "ping_ping_post",
        policyengine_full_api_client.PingRequest(value=12)
    )
    assert response.incremented == 13
