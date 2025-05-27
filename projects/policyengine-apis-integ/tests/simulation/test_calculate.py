import policyengine_simulation_api_client
import pytest

@pytest.mark.asyncio
async def test_calculation(async_client):
    options = policyengine_simulation_api_client.SimulationOptions(
        country="us",
        scope="macro",
        reform={
            "gov.irs.credits.ctc.refundable.fully_refundable": 
                policyengine_simulation_api_client.ParametricReformValue.from_dict({"2023-01-01.2100-12-31":True})
        },
        subsample=200, # reduce the number of households to speed things up.
        data=policyengine_simulation_api_client.Data("gs://policyengine-us-data/cps_2023.h5")
    )
    response = await async_client.call(
        "simulate_simulate_economy_comparison_post",
        options
    )
    assert response is not None