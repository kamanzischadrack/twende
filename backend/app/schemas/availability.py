import uuid
from datetime import datetime, date
from pydantic import BaseModel, ConfigDict
from app.core.enums import VehicleStatus, VehicleClass


class AvailabilitySearchQuery(BaseModel):
    start_datetime: datetime
    end_datetime: datetime
    branch_id: uuid.UUID | None = None
    category_id: uuid.UUID | None = None
    vehicle_class: VehicleClass | None = None
    min_seats: int | None = None
    min_payload_tonnes: float | None = None


class VehicleAvailabilityStatus(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    vehicle_id: uuid.UUID
    plate_number: str
    make: str
    model: str
    year: int
    category_id: uuid.UUID
    category_name: str
    branch_id: uuid.UUID
    current_status: VehicleStatus
    is_available: bool
    conflict_reason: str | None = None


class CategoryDailyCapacity(BaseModel):
    category_id: uuid.UUID
    category_name: str
    date: date
    total_vehicles: int
    available_vehicles: int
    reserved_vehicles: int
    rented_vehicles: int
    maintenance_vehicles: int


class AvailabilityGridRow(BaseModel):
    vehicle_id: uuid.UUID
    plate_number: str
    make: str
    model: str
    category_name: str
    branch_id: uuid.UUID
    timeline_blocks: list[dict]

