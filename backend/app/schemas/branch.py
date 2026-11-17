from uuid import UUID
from datetime import datetime

from pydantic import BaseModel, Field

from app.schemas.common import BaseResponse


class BranchCreate(BaseModel):
    name: str = Field(min_length=2, max_length=150)
    address: str = Field(min_length=2, max_length=255)

    latitude: float | None = None
    longitude: float | None = None

    opening_hours: dict = Field(default_factory=dict)


class BranchUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=2, max_length=150)
    address: str | None = Field(default=None, min_length=2, max_length=255)

    latitude: float | None = None
    longitude: float | None = None

    opening_hours: dict | None = None


class BranchResponse(BaseResponse):
    id: UUID
    tenant_id: UUID

    name: str
    address: str

    latitude: float | None
    longitude: float | None

    opening_hours: dict

    created_at: datetime
    updated_at: datetime