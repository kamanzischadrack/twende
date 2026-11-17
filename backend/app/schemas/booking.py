import uuid
from datetime import datetime
from pydantic import BaseModel, ConfigDict
from app.core.enums import BookingStatus, BookingSource, RentalType


class BookingExtraItem(BaseModel):
    name: str
    quantity: float = 1.0
    unit_price: float
    total_price: float


class BookingCreate(BaseModel):
    customer_id: uuid.UUID
    category_id: uuid.UUID
    vehicle_id: uuid.UUID | None = None
    rental_type: RentalType = RentalType.SELF_DRIVE
    pickup_branch_id: uuid.UUID
    return_branch_id: uuid.UUID | None = None
    start_datetime: datetime
    end_datetime: datetime
    rate_plan_id: uuid.UUID | None = None
    extras: list[BookingExtraItem] = []
    source: BookingSource = BookingSource.WALK_IN
    discount_amount: float = 0.0
    required_deposit: float = 50000.0
    notes: str | None = None


class BookingQuoteRequest(BaseModel):
    category_id: uuid.UUID
    vehicle_id: uuid.UUID | None = None
    start_datetime: datetime
    end_datetime: datetime
    rate_plan_id: uuid.UUID | None = None
    extras: list[BookingExtraItem] = []
    discount_code: str | None = None
    discount_percent: float = 0.0


class BookingQuoteResponse(BaseModel):
    duration_hours: float
    duration_days: float
    rental_charge: float
    extras_total: float
    discount_total: float
    subtotal: float
    tax_rate: float
    tax_amount: float
    grand_total: float
    deposit_required: float


class BookingResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    booking_number: str
    tenant_id: uuid.UUID
    customer_id: uuid.UUID
    category_id: uuid.UUID
    vehicle_id: uuid.UUID | None
    pickup_branch_id: uuid.UUID
    return_branch_id: uuid.UUID | None
    rental_type: RentalType
    start_datetime: datetime
    end_datetime: datetime
    status: BookingStatus
    source: BookingSource
    quoted_amount: float
    notes: str | None
    created_at: datetime


class BookingCancelRequest(BaseModel):
    reason: str
    cancellation_fee: float = 0.0

