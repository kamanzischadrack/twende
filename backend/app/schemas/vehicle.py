from uuid import UUID
from datetime import datetime
from pydantic import BaseModel, Field

from app.core.enums import VehicleStatus, OwnershipType
from app.schemas.common import BaseResponse


class VehicleBase(BaseModel):
    branch_id: UUID
    category_id: UUID
    plate_number: str = Field(min_length=2, max_length=20)
    vin: str | None = Field(default=None, max_length=50)
    make: str = Field(min_length=1, max_length=50)
    model: str = Field(min_length=1, max_length=50)
    year: int = Field(ge=1990, le=2050)
    color: str | None = Field(default=None, max_length=50)
    current_mileage: int = Field(default=0, ge=0)
    fuel_tank_capacity_l: float = Field(default=60.0, gt=0)
    current_fuel_level_pct: float = Field(default=100.0, ge=0, le=100)
    ownership_type: OwnershipType = OwnershipType.OWNED
    purchase_cost: float | None = Field(default=None, ge=0)
    annual_depreciation_rate: float | None = Field(default=None, ge=0, le=100)


class VehicleCreate(VehicleBase):
    pass


class VehicleUpdate(BaseModel):
    branch_id: UUID | None = None
    category_id: UUID | None = None
    plate_number: str | None = Field(default=None, min_length=2, max_length=20)
    vin: str | None = Field(default=None, max_length=50)
    make: str | None = Field(default=None, min_length=1, max_length=50)
    model: str | None = Field(default=None, min_length=1, max_length=50)
    year: int | None = Field(default=None, ge=1990, le=2050)
    color: str | None = Field(default=None, max_length=50)
    current_mileage: int | None = Field(default=None, ge=0)
    fuel_tank_capacity_l: float | None = Field(default=None, gt=0)
    current_fuel_level_pct: float | None = Field(default=None, ge=0, le=100)
    ownership_type: OwnershipType | None = None
    purchase_cost: float | None = Field(default=None, ge=0)
    annual_depreciation_rate: float | None = Field(default=None, ge=0, le=100)


class VehicleStatusOverride(BaseModel):
    new_status: VehicleStatus
    reason: str = Field(min_length=5, max_length=255)


class VehicleResponse(BaseResponse, VehicleBase):
    id: UUID
    tenant_id: UUID
    status: VehicleStatus
    status_reason: str | None
    created_at: datetime
    updated_at: datetime

