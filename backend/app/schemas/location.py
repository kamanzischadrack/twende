from uuid import UUID
from datetime import datetime

from pydantic import BaseModel, Field

from app.schemas.common import BaseResponse


class LocationCreate(BaseModel):
    name: str = Field(min_length=2, max_length=150)
    address: str = Field(min_length=2, max_length=255)

    latitude: float | None = None
    longitude: float | None = None


class LocationUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=2, max_length=150)
    address: str | None = Field(default=None, min_length=2, max_length=255)

    latitude: float | None = None
    longitude: float | None = None


class LocationResponse(BaseResponse):
    id: UUID
    tenant_id: UUID
    branch_id: UUID

    name: str
    address: str

    latitude: float | None
    longitude: float | None

    created_at: datetime
    updated_at: datetime