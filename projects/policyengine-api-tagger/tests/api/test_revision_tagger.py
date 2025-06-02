import pytest
from policyengine_api_tagger.api.revision_tagger import RevisionTagger
from urllib.parse import urlparse

from .common import (
    BucketDataFixture,
    CloudrunClientFixture,
    TEST_CLOUDRUN_HOSTNAME,
)


@pytest.mark.asyncio
async def test_given_metadata_exists__then_correctly_tags_revision(
    bucket_data: BucketDataFixture, cloudrun: CloudrunClientFixture
):
    tagger = RevisionTagger("TEST_BUCKET_NAME")

    bucket_data.given_metadata_exists_for(
        revision="projects/TEST_PROJECT/locations/TEST_LOCATION/services/TEST_SERVICE/revisions/TEST_REVISION",
        uri="https://revision1",
        us_model_version="US.TEST.REVISION",
        uk_model_version="UK.TEST.REVISION",
    )

    result = await tagger.tag("us", "US.TEST.REVISION")

    assert (
        result
        == f"https://country-us-model-US-TEST-REVISION---{TEST_CLOUDRUN_HOSTNAME}"
    )
    assert cloudrun.tags == {
        "projects/TEST_PROJECT/locations/TEST_LOCATION/services/TEST_SERVICE,TEST_REVISION": [
            "country-us-model-US-TEST-REVISION"
        ]
    }


@pytest.mark.asyncio
async def test_given_no_matching_revision__then_returns_none(
    bucket_data: BucketDataFixture, cloudrun: CloudrunClientFixture
):
    tagger = RevisionTagger("TEST_BUCKET")

    bucket_data.given_metadata_exists_for(
        revision="projects/TEST_PROJECT/locations/TEST_LOCATION/services/TEST_SERVICE/revisions/TEST_REVISION",
        uri="https://revision1",
        us_model_version="DIFFERENT.US.TEST.REVISION",
        uk_model_version="DIFFERENT.UK.TEST.REVISION",
    )

    result = await tagger.tag("us", "NO.SUCH.REVISION")

    assert result is None
    assert cloudrun.tags == {}
