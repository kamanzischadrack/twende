import uuid
from datetime import datetime
from pydantic import BaseModel, ConfigDict
from app.core.enums import ContractStatus, RentalType, ContractLineType


class ContractCreateFromBooking(BaseModel):
    booking_id: uuid.UUID
    assigned_driver_id: uuid.UUID | None = None
    terms: str | None = None


class HandoverRequest(BaseModel):
    starting_mileage: int
    fuel_level: float
    checklist: dict
    photos: list[str]
    customer_signature_url: str
    staff_signature_url: str | None = None


class ReturnRequest(BaseModel):
    return_datetime: datetime
    final_mileage: int
    fuel_level: float
    checklist: dict
    photos: list[str]
    cleaning_fee: float = 0.0
    damage_fee: float = 0.0
    missing_equipment_fee: float = 0.0
    customer_signature_url: str | None = None


class ExtensionRequest(BaseModel):
    new_expected_return: datetime
    reason: str | None = None


class VehicleSwapRequest(BaseModel):
    new_vehicle_id: uuid.UUID
    swap_mileage_old: int
    swap_fuel_old: float
    swap_mileage_new: int
    swap_fuel_new: float
    reason: str


class AddChargeRequest(BaseModel):
    line_type: ContractLineType
    description: str
    quantity: float = 1.0
    unit_price: float
    tax_rate: float = 0.18


class ContractLineResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    line_type: ContractLineType
    description: str
    quantity: float
    unit_price: float
    tax_rate: float
    tax_amount: float
    total_amount: float


class ContractResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    contract_number: str
    tenant_id: uuid.UUID
    booking_id: uuid.UUID | None
    customer_id: uuid.UUID
    vehicle_id: uuid.UUID
    pickup_branch_id: uuid.UUID
    return_branch_id: uuid.UUID | None
    start_datetime: datetime
    expected_return_datetime: datetime
    actual_return_datetime: datetime | None
    status: ContractStatus
    customer_signature_url: str | None
    lines: list[ContractLineResponse] = []
    created_at: datetime
