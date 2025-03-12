from uuid import UUID
from pydantic import RootModel, BaseModel
from typing import Annotated


class EntityDescription(RootModel):
    root: dict[
        Annotated[str, "An entity group, e.g., people"],
        list[Annotated[str, "An entity, e.g., 'your partner'"]],
    ]


class ComputationTree(BaseModel):
    uuid: UUID
    country_id: str
    tree: list[str]
    entity_description: EntityDescription
