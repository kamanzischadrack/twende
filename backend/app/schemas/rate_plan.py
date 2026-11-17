from uuid import UUID
from datetime import datetime
from pydantic import BaseModel, Field

from app.core.enums import FuelPolicy
from app.schemas.common import BaseResponse


class RatePlanBase(BaseModel):
    name: str = Field(min_length=2, max_length=100)
    category_id: UUID
    vehicle_id: UUID | None = None
    currency: str = Field(default="RWF", min_length=3, max_length=3)
    hourly_rate: float | None = Field(default=None, ge=0)
    daily_rate: float = Field(ge=0)
    weekly_rate: float = Field(ge=0)
    monthly_rate: float = Field(ge=0)
    included_km_per_day: int = Field(default=200, ge=0)
    excess_km_rate: float = Field(default=150.0, ge=0)
    fuel_policy: FuelPolicy = FuelPolicy.FULL_TO_FULL
    refuel_surcharge_fee: float = Field(default=5000.0, ge=0)
    grace_period_minutes: int = Field(default=60, ge=0)
    default_deposit_amount: float = Field(default=100000.0, ge=0)
    is_active: bool = True


class RatePlanCreate(RatePlanBase):
    pass


class RatePlanUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=2, max_length=100)
    category_id: UUID | None = None
    vehicle_id: UUID | None = None
    currency: str | None = Field(default=None, min_length=3, max_length=3)
    hourly_rate: float | None = Field(default=None, ge=0)
    daily_rate: float | None = Field(default=None, ge=0)
    weekly_rate: float | None = Field(default=None, ge=0)
    monthly_rate: float | None = Field(default=None, ge=0)
    included_km_per_day: int | None = Field(default=None, ge=0)
    excess_km_rate: float | None = Field(default=None, ge=0)
    fuel_policy: FuelPolicy | None = None
    refuel_surcharge_fee: float | None = Field(default=None, ge=0)
    grace_period_minutes: int | None = Field(default=None, ge=0)
    default_deposit_amount: float | None = Field(default=None, ge=0)
    is_active: bool | None = None


class RatePlanResponse(BaseResponse, RatePlanBase):
    id: UUID
    tenant_id: UUID
    created_at: datetime
    updated_at: datetime

