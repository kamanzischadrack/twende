
from uuid import UUID
from datetime import datetime

from pydantic import BaseModel, Field

from app.schemas.common import BaseResponse
from app.core.enums import UserStatus


class UserCreate(BaseModel):
    name: str = Field(min_length=2, max_length=150)
    phone: str = Field(min_length=5, max_length=30)
    email: str | None = None
    password: str = Field(min_length=8)
    branch_id: UUID | None = None


class UserUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=2, max_length=150)
    phone: str | None = Field(default=None, min_length=5, max_length=30)
    email: str | None = None
    branch_id: UUID | None = None
    status: UserStatus | None = None
    two_factor_enabled: bool | None = None


class UserResponse(BaseResponse):
    id: UUID
    tenant_id: UUID
    name: str
    phone: str
    email: str | None
    branch_id: UUID | None
    status: UserStatus
    two_factor_enabled: bool
    created_at: datetime
    updated_at: datetime
