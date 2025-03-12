from fastapi.testclient import TestClient


def test_started__returns_alive(client: TestClient):
    response = client.get("/ping/started")

    assert response.json() == 'alive'
    assert response.status_code == 200
