import uuid
from datetime import date
from pydantic import BaseModel, ConfigDict
from app.core.enums import WorkOrderType, WorkOrderStatus


class WorkOrderCreate(BaseModel):
    vehicle_id: uuid.UUID
    order_type: WorkOrderType = WorkOrderType.PREVENTIVE
    garage_name: str
    description: str
    parts_cost: float = 0.0
    labour_cost: float = 0.0
    start_date: date
    estimated_completion_date: date | None = None
    downtime_hours: int = 8


class WorkOrderUpdate(BaseModel):
    status: WorkOrderStatus | None = None
    garage_name: str | None = None
    parts_cost: float | None = None
    labour_cost: float | None = None
    actual_completion_date: date | None = None
    downtime_hours: int | None = None


class WorkOrderResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    order_number: str
    tenant_id: uuid.UUID
    vehicle_id: uuid.UUID
    order_type: WorkOrderType
    status: WorkOrderStatus
    garage_name: str
    description: str
    parts_cost: float
    labour_cost: float
    total_cost: float
    start_date: date
    estimated_completion_date: date | None
    actual_completion_date: date | None
    downtime_hours: int
