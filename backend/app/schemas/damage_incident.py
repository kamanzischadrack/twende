import uuid
from datetime import date, datetime
from pydantic import BaseModel, ConfigDict
from app.core.enums import (
    DamageType,
    DamageSeverity,
    DamageStatus,
    DamageLiability,
    IncidentType,
    IncidentStatus,
)


class DamageRecordCreate(BaseModel):
    vehicle_id: uuid.UUID
    contract_id: uuid.UUID | None = None
    customer_id: uuid.UUID | None = None
    discovery_date: date = date.today()
    damage_type: DamageType
    location_on_vehicle: str
    severity: DamageSeverity = DamageSeverity.LOW
    photos: list[str] = []
    estimated_repair_cost: float = 0.0
    liability: DamageLiability = DamageLiability.CUSTOMER


class DamageRecordUpdate(BaseModel):
    status: DamageStatus | None = None
    actual_repair_cost: float | None = None
    liability: DamageLiability | None = None


class DamageRecordResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    tenant_id: uuid.UUID
    vehicle_id: uuid.UUID
    contract_id: uuid.UUID | None
    customer_id: uuid.UUID | None
    discovery_date: date
    damage_type: DamageType
    location_on_vehicle: str
    severity: DamageSeverity
    photos: list[str]
    estimated_repair_cost: float
    actual_repair_cost: float
    liability: DamageLiability
    status: DamageStatus


class IncidentCreate(BaseModel):
    vehicle_id: uuid.UUID
    incident_type: IncidentType
    incident_date: date
    location: str
    contract_id: uuid.UUID | None = None
    driver_id: uuid.UUID | None = None
    evidence_url: str | None = None
    police_report_number: str | None = None
    fine_amount: float = 0.0
    is_recharged_to_customer: bool = False
    resolution_notes: str | None = None


class IncidentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    incident_number: str
    tenant_id: uuid.UUID
    vehicle_id: uuid.UUID
    contract_id: uuid.UUID | None
    driver_id: uuid.UUID | None
    incident_type: IncidentType
    incident_date: date
    location: str
    fine_amount: float
    is_recharged_to_customer: bool
    status: IncidentStatus
    resolution_notes: str | None

