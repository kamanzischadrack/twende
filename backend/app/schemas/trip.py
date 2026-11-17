import uuid
from datetime import datetime
from pydantic import BaseModel, ConfigDict
from app.core.enums import TripStatus, CargoType, TripCostType


class TripStopCreate(BaseModel):
    stop_order: int
    location_name: str
    address: str | None = None
    planned_arrival: datetime | None = None
    notes: str | None = None


class TripCostCreate(BaseModel):
    cost_type: TripCostType
    amount: float
    currency: str = "RWF"
    receipt_photo_url: str | None = None
    notes: str | None = None


class ProofOfDeliveryCreate(BaseModel):
    recipient_name: str
    signature_url: str
    delivery_photo_url: str | None = None
    delivered_at: datetime
    gps_latitude: float | None = None
    gps_longitude: float | None = None


class TripCreate(BaseModel):
    truck_id: uuid.UUID
    trailer_id: uuid.UUID | None = None
    driver_id: uuid.UUID | None = None
    customer_id: uuid.UUID
    origin: str
    destination: str
    cargo_type: CargoType = CargoType.GENERAL
    cargo_weight_tonnes: float
    cargo_volume_m3: float | None = None
    revenue: float
    planned_start: datetime
    planned_end: datetime
    stops: list[TripStopCreate] = []


class TripCostResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    cost_type: TripCostType
    amount: float
    currency: str = "RWF"
    receipt_photo_url: str | None = None
    notes: str | None = None


class TripStopResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    stop_order: int
    location_name: str
    stop_type: str = "WAYPOINT"
    address: str | None = None
    arrival_time: datetime | None = None
    departure_time: datetime | None = None
    status: str | None = None


class ProofOfDeliveryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    recipient_name: str
    signature_url: str
    delivery_photo_url: str | None = None
    delivered_at: datetime
    gps_latitude: float | None = None
    gps_longitude: float | None = None


class TripResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    trip_number: str
    tenant_id: uuid.UUID
    truck_id: uuid.UUID
    trailer_id: uuid.UUID | None = None
    driver_id: uuid.UUID | None = None
    customer_id: uuid.UUID
    origin: str
    destination: str
    cargo_type: CargoType
    cargo_weight_tonnes: float
    cargo_volume_m3: float | None = None
    revenue: float
    status: TripStatus
    planned_start: datetime
    planned_end: datetime
    actual_start: datetime | None = None
    actual_end: datetime | None = None
    total_costs: float = 0.0
    trip_margin: float = 0.0
    stops: list[TripStopResponse] = []
    costs: list[TripCostResponse] = []
    pod: ProofOfDeliveryResponse | None = None
    proof_of_delivery: ProofOfDeliveryResponse | None = None
