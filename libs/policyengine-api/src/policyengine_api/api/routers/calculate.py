from fastapi import APIRouter, Body
from typing import Any
from policyengine_api.api.enums import COUNTRY_ID
from uuid import UUID
from policyengine_api.api.models.household import (
    HouseholdUS,
    HouseholdUK,
    HouseholdGeneric,
    example_household_input_us,
)
from policyengine_api.api.models.endpoints.calculate import CalculateResponse
from policyengine_api.api.country import COUNTRIES
from typing import Annotated


router = APIRouter()


@router.post("/{country_id}/calculate")
async def calculate(
    country_id: COUNTRY_ID,
    household: Annotated[
        HouseholdGeneric | HouseholdUK | HouseholdUS,
        Body(examples=[example_household_input_us]),
    ],
    enable_ai_explainer: Annotated[bool, Body()] = False,
) -> CalculateResponse:

    # Household models above currently conflict with models defined in
    # household/household.py; the household routes will be brought in
    # line in later iteration
    country = COUNTRIES.get(country_id.value)

    result: HouseholdGeneric | HouseholdUK | HouseholdUS
    computation_tree_uuid: UUID | None
    result, computation_tree_uuid = country.calculate(
        household=household,
        reform=None,
        enable_ai_explainer=enable_ai_explainer,
    )

    # Note - computation_tree_uuid will be either None or a random UUID until GCP
    # uploading is added in a future PR
    return CalculateResponse(
        result=result, computation_tree_uuid=computation_tree_uuid
    )
