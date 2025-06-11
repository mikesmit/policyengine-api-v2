from unittest.mock import AsyncMock, patch
import pytest
from fastapi.testclient import TestClient
from fastapi import FastAPI

from policyengine_api_tagger.api.revision_tagger import RevisionTagger
from policyengine_api_tagger.api.routes import add_all_routes
from .common import CloudrunClientFixture, BucketDataFixture


@pytest.fixture
def client(
    cloudrun: CloudrunClientFixture, bucket_data: BucketDataFixture
) -> TestClient:
    app = FastAPI(
        title="policyengine-api-tagger",
        summary="Internal service that tags revisions of the simulation api",
    )

    tagger = RevisionTagger("TEST_BUCKET_NAME")
    add_all_routes(app, tagger)

    return TestClient(app)


def test_given_model_valid__returns_tag_url(
    client: TestClient,
    cloudrun: CloudrunClientFixture,
    bucket_data: BucketDataFixture,
):
    bucket_data.given_metadata_exists_for(us_model_version="1.2.3")
    response = client.get("/tag?country=us&model_version=1.2.3")
    assert response.status_code == 200
    assert response.json() == f"https://country-us-model-1-2-3---{cloudrun.hostname}"


def text_given_model_not_exists__returns_404(
    client: TestClient,
    cloudrun: CloudrunClientFixture,
    bucket_data: BucketDataFixture,
):
    response = client.get("/tag?country=us&model_version=no.such.version")
    assert response.status_code == 404
