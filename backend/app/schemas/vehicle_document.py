from uuid import UUID
from datetime import date, datetime
from pydantic import BaseModel, Field

from app.core.enums import VehicleDocumentType
from app.schemas.common import BaseResponse


class VehicleDocumentBase(BaseModel):
    document_type: VehicleDocumentType
    document_number: str = Field(min_length=2, max_length=100)
    issue_date: date | None = None
    expiry_date: date
    file_url: str | None = Field(default=None, max_length=500)
    is_critical: bool = True
    notes: str | None = Field(default=None, max_length=500)


class VehicleDocumentCreate(VehicleDocumentBase):
    pass


class VehicleDocumentUpdate(BaseModel):
    document_type: VehicleDocumentType | None = None
    document_number: str | None = Field(default=None, min_length=2, max_length=100)
    issue_date: date | None = None
    expiry_date: date | None = None
    file_url: str | None = Field(default=None, max_length=500)
    is_critical: bool | None = None
    notes: str | None = Field(default=None, max_length=500)


class VehicleDocumentResponse(BaseResponse, VehicleDocumentBase):
    id: UUID
    tenant_id: UUID
    vehicle_id: UUID
    created_at: datetime
    updated_at: datetime

