from uuid import UUID
from datetime import date, datetime
from pydantic import BaseModel, Field, EmailStr

from app.core.enums import CustomerType, RiskStatus
from app.schemas.common import BaseResponse


class CustomerBase(BaseModel):
    customer_type: CustomerType = CustomerType.INDIVIDUAL
    name: str = Field(min_length=2, max_length=150)
    trade_name: str | None = Field(default=None, max_length=150)
    tin_number: str | None = Field(default=None, max_length=50)
    phone: str = Field(min_length=8, max_length=30)
    email: EmailStr | None = None
    national_id_or_passport: str | None = Field(default=None, max_length=50)
    driving_licence_number: str | None = Field(default=None, max_length=50)
    licence_expiry_date: date | None = None
    licence_classes: list[str] = Field(default_factory=list)
    risk_status: RiskStatus = RiskStatus.CLEAR
    risk_notes: str | None = Field(default=None, max_length=500)
    credit_limit: float = Field(default=0.0, ge=0)
    is_tax_exempt: bool = False


class CustomerCreate(CustomerBase):
    pass


class CustomerUpdate(BaseModel):
    customer_type: CustomerType | None = None
    name: str | None = Field(default=None, min_length=2, max_length=150)
    trade_name: str | None = Field(default=None, max_length=150)
    tin_number: str | None = Field(default=None, max_length=50)
    phone: str | None = Field(default=None, min_length=8, max_length=30)
    email: EmailStr | None = None
    national_id_or_passport: str | None = Field(default=None, max_length=50)
    driving_licence_number: str | None = Field(default=None, max_length=50)
    licence_expiry_date: date | None = None
    licence_classes: list[str] | None = None
    risk_status: RiskStatus | None = None
    risk_notes: str | None = Field(default=None, max_length=500)
    credit_limit: float | None = Field(default=None, ge=0)
    is_tax_exempt: bool | None = None


class CustomerRiskUpdate(BaseModel):
    risk_status: RiskStatus
    risk_notes: str = Field(min_length=3, max_length=500)


class CustomerResponse(BaseResponse, CustomerBase):
    id: UUID
    tenant_id: UUID
    outstanding_balance: float
    created_at: datetime
    updated_at: datetime

