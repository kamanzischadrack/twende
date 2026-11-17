from uuid import UUID
from datetime import datetime
from pydantic import BaseModel, Field

from app.schemas.common import BaseResponse
from app.core.enums import TenantStatus


class TenantCreate(BaseModel):
    name: str = Field(min_length=2, max_length=150)
    country: str = Field(default="Rwanda", min_length=2, max_length=100)
    currency: str = Field(default="RWF", min_length=3, max_length=3)
    contact_email: str | None = None
    contact_phone: str | None = None
    tin_number: str | None = None
    tax_settings: dict = Field(default_factory=dict)


class TenantUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=2, max_length=150)
    country: str | None = Field(default=None, min_length=2, max_length=100)
    currency: str | None = Field(default=None, min_length=3, max_length=3)
    contact_email: str | None = None
    contact_phone: str | None = None
    tin_number: str | None = None
    status: TenantStatus | None = None
    tax_settings: dict | None = None


class TenantResponse(BaseResponse):
    id: UUID
    name: str
    country: str
    currency: str
    status: TenantStatus
    contact_email: str | None = None
    contact_phone: str | None = None
    tin_number: str | None = None
    tax_settings: dict
    created_at: datetime
    updated_at: datetime
