from pydantic import BaseModel
from uuid import UUID
from policyengine_api.api.models.household import (
    HouseholdGeneric,
    HouseholdUK,
    HouseholdUS,
)


class CalculateResponse(BaseModel):
    result: HouseholdGeneric | HouseholdUK | HouseholdUS
    computation_tree_uuid: UUID | None = None
