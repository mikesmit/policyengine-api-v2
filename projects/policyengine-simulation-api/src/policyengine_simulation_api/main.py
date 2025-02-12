# projects/policyengine-api-household/src/policyengine_api_full/main.py

from fastapi import FastAPI
from sqlmodel import SQLModel
from contextlib import asynccontextmanager
from policyengine.fastapi.database import create_sqlite_engine
from policyengine.fastapi.auth import JWTDecoder
from .settings import get_settings, Environment
from policyengine.fastapi.opentelemetry import (
    GCPLoggingInstrumentor, 
    FastAPIEnhancedInstrumenter, 
    export_ot_to_console, 
    export_ot_to_gcp
)
from opentelemetry.sdk.resources import SERVICE_NAME, SERVICE_INSTANCE_ID, Resource
from opentelemetry.instrumentation.sqlalchemy import SQLAlchemyInstrumentor
from policyengine.api import initialize
from policyengine.api.simulation.router import create_simulation_router
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
# import our new simulation router

import logging

logger = logging.getLogger(__name__)

engine = create_sqlite_engine()

@asynccontextmanager
async def lifespan(app: FastAPI):
    SQLModel.metadata.create_all(engine)
    yield

app = FastAPI(lifespan=lifespan)

# The existing "initialize" call attaches household/user routes, etc.
initialize(
    app=app,
    engine=engine,
    jwt_issuer=get_settings().jwt_issuer,
    jwt_audience=get_settings().jwt_audience
)

# If we want to attach the simulation router with the same dependencies:
auth = JWTDecoder(
    issuer=get_settings().jwt_issuer,
    audience=get_settings().jwt_audience,
    auto_error=True
)
optional_auth = JWTDecoder(
    issuer=get_settings().jwt_issuer,
    audience=get_settings().jwt_audience,
    auto_error=False
)

from policyengine.fastapi.database import create_session_dep
session_dep = create_session_dep(engine)

sim_router = create_simulation_router(
    session_dependency=session_dep,
    optional_auth=optional_auth,
    auth=auth
)
app.include_router(sim_router)

# set up telemetry as before
GCPLoggingInstrumentor().instrument()
FastAPIEnhancedInstrumenter().instrument(app)
SQLAlchemyInstrumentor().instrument(engine=engine, enable_commenter=True, commenter_options={})

resource = Resource.create(
    attributes={
        SERVICE_NAME: get_settings().ot_service_name,
        SERVICE_INSTANCE_ID: get_settings().ot_service_instance_id,
    }
)

match(get_settings().environment):
    case Environment.DESKTOP:
        export_ot_to_console(resource)
    case Environment.PRODUCTION:
        export_ot_to_gcp(resource)
    case _:
        logger.warning("Unknown environment, no OT exporter configured.")
