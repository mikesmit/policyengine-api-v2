from fastapi import FastAPI, HTTPException
from fastapi.routing import APIRouter

from policyengine_api_tagger.api.revision_tagger import RevisionTagger


def create_router(tagger: RevisionTagger) -> APIRouter:
    router = APIRouter()

    @router.get("/tag")
    async def get_tag_uri(country: str, model_version: str) -> str:
        uri = await tagger.tag(country, model_version)
        if uri is None:
            raise HTTPException(status_code=404, detail="Item not found")
        return uri

    return router


def add_all_routes(api: FastAPI, tagger: RevisionTagger):
    api.include_router(create_router(tagger))
