
from uuid import UUID
from datetime import datetime

from pydantic import BaseModel, Field

from app.schemas.common import BaseResponse
from app.core.enums import RoleDevice


class RoleCreate(BaseModel):
    code: str = Field(min_length=2, max_length=100)
    name: str = Field(min_length=2, max_length=100)
    description: str | None = None
    primary_device: RoleDevice


class RoleUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=2, max_length=100)
    description: str | None = None
    primary_device: RoleDevice | None = None


class RoleResponse(BaseResponse):
    id: UUID
    tenant_id: UUID
    code: str
    name: str
    description: str | None
    primary_device: RoleDevice
    created_at: datetime
    updated_at: datetime
