import policyengine_simulation_api_client
import pytest
from pydantic_settings import BaseSettings, SettingsConfigDict
import asyncio

class Settings(BaseSettings):
    base_url: str = "http://localhost:8001"
    access_token: str | None = None
    timeout_in_millis: int = 200

    model_config = SettingsConfigDict(env_prefix="simulation_integ_test_")


settings = Settings()

@pytest.fixture()
def client() -> policyengine_simulation_api_client.DefaultApi:
    config = policyengine_simulation_api_client.Configuration(host=settings.base_url)
    client = policyengine_simulation_api_client.ApiClient(config)
    if settings.access_token:
        client.default_headers["Authorization"] = (
            f"Bearer {settings.access_token}"
        )
    return policyengine_simulation_api_client.DefaultApi(client)

# Async client wrapper around sync client
@pytest.fixture
def async_client(client):
    class AsyncClientWrapper:
        def __init__(self, client):
            self._client = client

        async def call(self, func_name, *args, **kwargs):
            func = getattr(self._client, func_name)
            return await asyncio.to_thread(func, *args, **kwargs)

    return AsyncClientWrapper(client)