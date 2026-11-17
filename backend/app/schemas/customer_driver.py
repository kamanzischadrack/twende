from uuid import UUID
from datetime import date, datetime
from pydantic import BaseModel, Field

from app.schemas.common import BaseResponse


class CustomerDriverBase(BaseModel):
    customer_id: UUID
    full_name: str = Field(min_length=2, max_length=150)
    phone: str = Field(min_length=8, max_length=30)
    licence_number: str = Field(min_length=2, max_length=50)
    licence_expiry_date: date
    licence_classes: list[str] = Field(default_factory=list)


class CustomerDriverCreate(CustomerDriverBase):
    pass


class CustomerDriverUpdate(BaseModel):
    full_name: str | None = Field(default=None, min_length=2, max_length=150)
    phone: str | None = Field(default=None, min_length=8, max_length=30)
    licence_number: str | None = Field(default=None, min_length=2, max_length=50)
    licence_expiry_date: date | None = None
    licence_classes: list[str] | None = None


class CustomerDriverResponse(BaseResponse, CustomerDriverBase):
    id: UUID
    tenant_id: UUID
    created_at: datetime
    updated_at: datetime

