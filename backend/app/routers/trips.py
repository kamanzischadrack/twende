import uuid
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import select

from app.core.database import get_db
from app.dependencies.auth import get_current_user
from app.models.user import User
from app.models.trip import Trip
from app.core.enums import TripStatus
from app.schemas.trip import (
    TripCreate,
    TripCostCreate,
    ProofOfDeliveryCreate,
    TripResponse,
    TripCostResponse,
    ProofOfDeliveryResponse,
)
from app.services.trip_service import (
    create_trip,
    add_trip_cost,
    record_proof_of_delivery,
    close_trip,
)

router = APIRouter(prefix="/trips", tags=["trips"])


@router.post("", response_model=TripResponse, status_code=status.HTTP_201_CREATED)
def make_trip(
    req: TripCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return create_trip(
        db=db,
        tenant_id=current_user.tenant_id,
        data=req,
        user_id=current_user.id,
    )


@router.get("", response_model=list[TripResponse])
def list_all_trips(
    trip_status: TripStatus | None = None,
    truck_id: uuid.UUID | None = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    query = select(Trip).where(Trip.tenant_id == current_user.tenant_id)
    if trip_status:
        query = query.where(Trip.status == trip_status)
    if truck_id:
        query = query.where(Trip.truck_id == truck_id)
    query = query.order_by(Trip.created_at.desc())
    return list(db.execute(query).scalars().all())


@router.get("/{trip_id}", response_model=TripResponse)
def get_single_trip(
    trip_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    trip = db.execute(
        select(Trip).where(
            Trip.id == trip_id,
            Trip.tenant_id == current_user.tenant_id,
        )
    ).scalar_one_or_none()

    if not trip:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Trip not found")

    return trip


@router.post("/{trip_id}/costs", response_model=TripCostResponse)
def log_cost(
    trip_id: uuid.UUID,
    req: TripCostCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return add_trip_cost(
        db=db,
        tenant_id=current_user.tenant_id,
        trip_id=trip_id,
        data=req,
    )


@router.post("/{trip_id}/pod", response_model=ProofOfDeliveryResponse)
def submit_pod(
    trip_id: uuid.UUID,
    req: ProofOfDeliveryCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return record_proof_of_delivery(
        db=db,
        tenant_id=current_user.tenant_id,
        trip_id=trip_id,
        data=req,
    )


@router.post("/{trip_id}/close")
def close_trip_and_calculate_margin(
    trip_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return close_trip(
        db=db,
        tenant_id=current_user.tenant_id,
        trip_id=trip_id,
    )

