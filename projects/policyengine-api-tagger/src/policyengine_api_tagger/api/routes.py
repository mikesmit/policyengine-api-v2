from fastapi import FastAPI, HTTPException
from fastapi.routing import APIRouter

from policyengine_api_tagger.api.revision_tagger import RevisionTagger
import logging

log = logging.getLogger(__file__)

def create_router(tagger: RevisionTagger) -> APIRouter:
    router = APIRouter()

    @router.get("/tag")
    async def get_tag_uri(country: str, model_version: str) -> str:
        uri = await tagger.tag(country, model_version)
        if uri is None:
            log.info(f"No tag url for country {country}, model_version {model_version}")
            raise HTTPException(status_code=404, detail="Item not found")
        log.info(f"Got URI {uri} for country {country} model_version {model_version}")
        return uri

    return router


def add_all_routes(api: FastAPI, tagger: RevisionTagger):
    api.include_router(create_router(tagger))
