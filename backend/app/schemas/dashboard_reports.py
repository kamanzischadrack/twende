import uuid
from datetime import date
from pydantic import BaseModel


class FleetKPIs(BaseModel):
    total_vehicles: int
    available: int
    reserved: int
    rented: int
    under_maintenance: int
    out_of_service: int
    trucks_on_trip: int


class BusinessKPIs(BaseModel):
    total_revenue: float
    total_outstanding: float
    deposits_held: float
    total_rental_days: int
    utilization_rate_pct: float
    average_daily_rate: float
    rev_pav: float
    vehicle_contribution_margin: float


class OperationsKPIs(BaseModel):
    active_rentals: int
    overdue_rentals: int
    pickups_today: int
    returns_today: int
    maintenance_due: int
    expiring_documents: int


class DashboardSummaryResponse(BaseModel):
    fleet: FleetKPIs
    business: BusinessKPIs
    operations: OperationsKPIs


class VehicleProfitabilityRow(BaseModel):
    vehicle_id: uuid.UUID
    plate_number: str
    make: str
    model: str
    category_name: str
    rental_revenue: float
    discounts: float
    maintenance_cost: float
    fuel_cost: float
    insurance_cost: float
    depreciation: float
    unrecovered_damage_cost: float
    vehicle_contribution: float
    utilization_pct: float
    rev_pav: float


class VehicleProfitabilityReport(BaseModel):
    period_start: date
    period_end: date
    total_contribution: float
    vehicles: list[VehicleProfitabilityRow]


class AlertItem(BaseModel):
    alert_type: str
    severity: str
    title: str
    message: str
    reference_id: uuid.UUID | None = None
    target_role: str

