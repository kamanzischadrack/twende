import uuid
from datetime import datetime, timezone, date, time
from sqlalchemy.orm import Session
from sqlalchemy import select, func
from fastapi import HTTPException, status

from app.models.work_order import WorkOrder
from app.models.vehicle import Vehicle
from app.core.enums import WorkOrderStatus, VehicleStatus
from app.schemas.maintenance import WorkOrderCreate, WorkOrderUpdate
from app.services.availability_service import availability_service


def create_work_order(
    db: Session,
    tenant_id: uuid.UUID,
    data: WorkOrderCreate,
    user_id: uuid.UUID | None = None,
) -> WorkOrder:
    vehicle = db.execute(
        select(Vehicle).where(
            Vehicle.id == data.vehicle_id,
            Vehicle.tenant_id == tenant_id,
        )
    ).scalar_one_or_none()

    if not vehicle:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Vehicle not found")

    order_num = f"WO-{datetime.now(timezone.utc).strftime('%Y%m%d')}-{uuid.uuid4().hex[:6].upper()}"
    parts = float(data.parts_cost)
    labour = float(data.labour_cost)
    total = parts + labour

    order = WorkOrder(
        tenant_id=tenant_id,
        order_number=order_num,
        vehicle_id=data.vehicle_id,
        order_type=data.order_type,
        status=WorkOrderStatus.SCHEDULED,
        garage_name=data.garage_name,
        description=data.description,
        parts_cost=parts,
        labour_cost=labour,
        total_cost=total,
        start_date=data.start_date,
        estimated_completion_date=data.estimated_completion_date or data.start_date,
        downtime_hours=data.downtime_hours,
        created_by=user_id,
    )
    db.add(order)
    db.flush()

    vehicle.status = VehicleStatus.UNDER_MAINTENANCE

    start_dt = datetime.combine(data.start_date, time.min, tzinfo=timezone.utc)
    end_dt = datetime.combine(order.estimated_completion_date, time.max, tzinfo=timezone.utc)

    availability_service.create_availability_block(
        db=db,
        tenant_id=tenant_id,
        vehicle_id=vehicle.id,
        start_time=start_dt,
        end_time=end_dt,
        block_type="MAINTENANCE",
        reference_id=order.id,
    )

    db.commit()
    db.refresh(order)
    return order


def update_work_order(
    db: Session,
    tenant_id: uuid.UUID,
    order_id: uuid.UUID,
    data: WorkOrderUpdate,
    user_id: uuid.UUID | None = None,
) -> WorkOrder:
    order = db.execute(
        select(WorkOrder).where(
            WorkOrder.id == order_id,
            WorkOrder.tenant_id == tenant_id,
        )
    ).scalar_one_or_none()

    if not order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Work order not found")

    if data.garage_name is not None:
        order.garage_name = data.garage_name
    if data.parts_cost is not None:
        order.parts_cost = float(data.parts_cost)
    if data.labour_cost is not None:
        order.labour_cost = float(data.labour_cost)
    if data.parts_cost is not None or data.labour_cost is not None:
        order.total_cost = float(order.parts_cost) + float(order.labour_cost)
    if data.actual_completion_date is not None:
        order.actual_completion_date = data.actual_completion_date
    if data.downtime_hours is not None:
        order.downtime_hours = data.downtime_hours

    if data.status is not None:
        order.status = data.status
        if data.status == WorkOrderStatus.COMPLETED:
            if not order.actual_completion_date:
                order.actual_completion_date = date.today()

            vehicle = db.execute(select(Vehicle).where(Vehicle.id == order.vehicle_id)).scalar_one_or_none()
            if vehicle and vehicle.status == VehicleStatus.UNDER_MAINTENANCE:
                vehicle.status = VehicleStatus.AVAILABLE

            availability_service.release_availability_block(db, tenant_id, order.id)

    db.commit()
    db.refresh(order)
    return order


def get_vehicle_maintenance_summary(
    db: Session,
    tenant_id: uuid.UUID,
    vehicle_id: uuid.UUID,
) -> dict:
    total_cost = db.execute(
        select(func.sum(WorkOrder.total_cost)).where(
            WorkOrder.vehicle_id == vehicle_id,
            WorkOrder.tenant_id == tenant_id,
        )
    ).scalar() or 0.0

    count = db.execute(
        select(func.count(WorkOrder.id)).where(
            WorkOrder.vehicle_id == vehicle_id,
            WorkOrder.tenant_id == tenant_id,
        )
    ).scalar() or 0

    return {
        "vehicle_id": vehicle_id,
        "total_maintenance_cost": float(total_cost),
        "work_order_count": count,
    }

