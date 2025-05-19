from typing import Annotated
import os
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from policyengine.simulation import SimulationOptions, Simulation
from policyengine.outputs.macro.comparison.calculate_economy_comparison import (
    EconomyComparison,
)
from pathlib import Path


def create_router():
    router = APIRouter()

    @router.post(
        "/simulate/economy/comparison", response_model=EconomyComparison
    )
    async def simulate(parameters: SimulationOptions) -> EconomyComparison:
        model = SimulationOptions.model_validate(parameters)
        print("Initialising")
        simulation = Simulation(**model.model_dump())
        print("Calculating")
        result = simulation.calculate_economy_comparison()
        # Clear data files

        for file in Path(".").glob("*.csv"):
            file.unlink()

        for file in Path(".").glob("*.h5"):
            file.unlink()

        return result

    return router
