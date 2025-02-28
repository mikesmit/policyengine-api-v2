from fastapi.testclient import TestClient
import pytest

from fastapi import FastAPI
from policyengine_api.fastapi import ping

@pytest.fixture
def client()->TestClient:
    api = FastAPI()
    ping.include_all_routers(api)
    return TestClient(api)

def test_execute_ping_increments_request_value(client:TestClient):
    response = client.post("/ping", json={"value":10})

    assert response.json() == {"incremented":11}