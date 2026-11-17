from uuid import UUID
from datetime import datetime
from pydantic import BaseModel, Field

from app.core.enums import VehicleClass, BodyType, TransmissionType, FuelType
from app.schemas.common import BaseResponse


class VehicleCategoryBase(BaseModel):
    name: str = Field(min_length=2, max_length=100)
    vehicle_class: VehicleClass = VehicleClass.CAR
    body_type: BodyType
    seats: int | None = Field(default=None, ge=1, le=100)
    doors: int | None = Field(default=None, ge=1, le=10)
    payload_capacity_tonnes: float | None = Field(default=None, ge=0)
    cargo_volume_m3: float | None = Field(default=None, ge=0)
    transmission: TransmissionType = TransmissionType.AUTOMATIC
    fuel_type: FuelType = FuelType.PETROL
    description: str | None = Field(default=None, max_length=500)


class VehicleCategoryCreate(VehicleCategoryBase):
    pass


class VehicleCategoryUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=2, max_length=100)
    vehicle_class: VehicleClass | None = None
    body_type: BodyType | None = None
    seats: int | None = Field(default=None, ge=1, le=100)
    doors: int | None = Field(default=None, ge=1, le=10)
    payload_capacity_tonnes: float | None = Field(default=None, ge=0)
    cargo_volume_m3: float | None = Field(default=None, ge=0)
    transmission: TransmissionType | None = None
    fuel_type: FuelType | None = None
    description: str | None = Field(default=None, max_length=500)


class VehicleCategoryResponse(BaseResponse, VehicleCategoryBase):
    id: UUID
    tenant_id: UUID
    created_at: datetime
    updated_at: datetime

