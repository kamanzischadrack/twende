
from uuid import UUID
from datetime import datetime

from pydantic import BaseModel, Field

from app.schemas.common import BaseResponse


class PermissionCreate(BaseModel):
    key: str = Field(min_length=3, max_length=150)
    resource: str = Field(min_length=2, max_length=100)
    action: str = Field(min_length=2, max_length=100)
    description: str | None = None


class PermissionUpdate(BaseModel):
    key: str | None = Field(default=None, min_length=3, max_length=150)
    resource: str | None = Field(default=None, min_length=2, max_length=100)
    action: str | None = Field(default=None, min_length=2, max_length=100)
    description: str | None = None


class PermissionResponse(BaseResponse):
    id: UUID
    tenant_id: UUID
    key: str
    resource: str
    action: str
    description: str | None
    created_at: datetime
    updated_at: datetime
