import uuid
from datetime import datetime, date
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.dependencies.auth import get_current_user
from app.models.user import User
from app.schemas.availability import (
    AvailabilitySearchQuery,
    VehicleAvailabilityStatus,
    CategoryDailyCapacity,
)
from app.services.availability_service import availability_service

router = APIRouter(prefix="/availability", tags=["availability"])
public_router = APIRouter(prefix="/public", tags=["public"])


@router.post("/search", response_model=list[VehicleAvailabilityStatus])
def search_vehicles(
    query: AvailabilitySearchQuery,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return availability_service.search_available_vehicles(
        db=db,
        tenant_id=current_user.tenant_id,
        start_datetime=query.start_datetime,
        end_datetime=query.end_datetime,
        branch_id=query.branch_id,
        category_id=query.category_id,
        min_seats=query.min_seats,
        min_payload_tonnes=query.min_payload_tonnes,
    )


@router.get("/capacity", response_model=list[CategoryDailyCapacity])
def get_daily_capacity(
    start_date: date = Query(...),
    end_date: date = Query(...),
    branch_id: uuid.UUID | None = Query(None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return availability_service.get_category_daily_capacity(
        db=db,
        tenant_id=current_user.tenant_id,
        start_date=start_date,
        end_date=end_date,
        branch_id=branch_id,
    )


@router.get("/check/{vehicle_id}")
def check_vehicle(
    vehicle_id: uuid.UUID,
    start_datetime: datetime = Query(...),
    end_datetime: datetime = Query(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    is_avail, conflict = availability_service.check_vehicle_availability(
        db=db,
        tenant_id=current_user.tenant_id,
        vehicle_id=vehicle_id,
        start_datetime=start_datetime,
        end_datetime=end_datetime,
    )
    return {
        "vehicle_id": vehicle_id,
        "is_available": is_avail,
        "conflict_reason": conflict,
    }


@public_router.get("/availability")
def public_availability_search(
    tenant_id: uuid.UUID = Query(...),
    start_datetime: datetime = Query(...),
    end_datetime: datetime = Query(...),
    category_id: uuid.UUID | None = Query(None),
    db: Session = Depends(get_db),
):
    results = availability_service.search_available_vehicles(
        db=db,
        tenant_id=tenant_id,
        start_datetime=start_datetime,
        end_datetime=end_datetime,
        category_id=category_id,
    )
    return [r for r in results if r["is_available"]]

