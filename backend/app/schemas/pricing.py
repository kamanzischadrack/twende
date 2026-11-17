from uuid import UUID
from datetime import datetime
from pydantic import BaseModel, Field


class PricingQuoteRequest(BaseModel):
    category_id: UUID
    vehicle_id: UUID | None = None
    start_datetime: datetime
    end_datetime: datetime
    rate_plan_id: UUID | None = None
    discount_pct: float = Field(default=0.0, ge=0.0, le=100.0)


class PricingBreakdownItem(BaseModel):
    unit_type: str
    units: int
    unit_rate: float
    subtotal: float
    applied_capping: bool = False
    capping_description: str | None = None


class PricingQuoteResponse(BaseModel):
    category_id: UUID
    vehicle_id: UUID | None
    rate_plan_id: UUID
    currency: str
    duration_days: int
    duration_hours: int
    breakdown: list[PricingBreakdownItem]
    rental_charge: float
    discount_pct: float
    discount_amount: float
    net_rental_charge: float
    tax_rate: float
    tax_amount: float
    total_quote: float
    required_deposit: float
    included_km_total: int
    excess_km_rate: float
