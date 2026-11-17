import uuid
from datetime import date, datetime
from pydantic import BaseModel, ConfigDict
from app.core.enums import DriverStatus


class DriverCreate(BaseModel):
    full_name: str
    phone: str
    email: str | None = None
    licence_number: str
    licence_classes: list[str] = ["B"]
    licence_expiry_date: date
    daily_rate: float = 0.0


class DriverUpdate(BaseModel):
    full_name: str | None = None
    phone: str | None = None
    email: str | None = None
    licence_classes: list[str] | None = None
    licence_expiry_date: date | None = None
    daily_rate: float | None = None
    status: DriverStatus | None = None


class DriverResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    tenant_id: uuid.UUID
    full_name: str
    phone: str
    email: str | None
    licence_number: str
    licence_classes: list[str]
    licence_expiry_date: date
    daily_rate: float
    status: DriverStatus
    created_at: datetime

