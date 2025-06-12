from fastapi.testclient import TestClient


def test_execute_ping_increments_request_value(client: TestClient):
    response = client.post("/ping", json={"value": 10})

    assert response.json() == {"incremented": 11}
