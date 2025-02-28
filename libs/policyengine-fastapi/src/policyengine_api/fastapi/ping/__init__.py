from fastapi import FastAPI, APIRouter
from pydantic import BaseModel
class PingRequest(BaseModel):
    value:int

class PingResponse(BaseModel):
    incremented:int


def create_router()->APIRouter:
    router = APIRouter()

    @router.post("/ping")
    async def ping(request:PingRequest)->PingResponse:
        '''
        verify the api is able to recieve and process unauthenticated requests.
        '''
        return PingResponse(incremented=request.value + 1)

    return router

def include_all_routers(api:FastAPI):
    api.include_router(create_router())