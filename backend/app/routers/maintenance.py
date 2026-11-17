import uuid
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from sqlalchemy import select

from app.core.database import get_db
from app.dependencies.auth import get_current_user
from app.models.user import User
from app.models.work_order import WorkOrder
from app.schemas.maintenance import (
    WorkOrderCreate,
    WorkOrderUpdate,
    WorkOrderResponse,
)
from app.services.maintenance_service import (
    create_work_order,
    update_work_order,
    get_vehicle_maintenance_summary,
)

router = APIRouter(prefix="/maintenance", tags=["maintenance"])


@router.post("/work-orders", response_model=WorkOrderResponse, status_code=status.HTTP_201_CREATED)
def make_work_order(
    req: WorkOrderCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return create_work_order(
        db=db,
        tenant_id=current_user.tenant_id,
        data=req,
        user_id=current_user.id,
    )


@router.get("/work-orders", response_model=list[WorkOrderResponse])
def list_orders(
    vehicle_id: uuid.UUID | None = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    query = select(WorkOrder).where(WorkOrder.tenant_id == current_user.tenant_id)
    if vehicle_id:
        query = query.where(WorkOrder.vehicle_id == vehicle_id)
    query = query.order_by(WorkOrder.start_date.desc())
    return list(db.execute(query).scalars().all())


@router.put("/work-orders/{order_id}", response_model=WorkOrderResponse)
def modify_work_order(
    order_id: uuid.UUID,
    req: WorkOrderUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return update_work_order(
        db=db,
        tenant_id=current_user.tenant_id,
        order_id=order_id,
        data=req,
        user_id=current_user.id,
    )


@router.get("/summary/{vehicle_id}")
def vehicle_maintenance_summary(
    vehicle_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return get_vehicle_maintenance_summary(
        db=db,
        tenant_id=current_user.tenant_id,
        vehicle_id=vehicle_id,
    )

