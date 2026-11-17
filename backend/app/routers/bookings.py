import uuid
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import select

from app.core.database import get_db
from app.dependencies.auth import get_current_user
from app.models.user import User
from app.models.booking import Booking
from app.schemas.booking import (
    BookingCreate,
    BookingQuoteRequest,
    BookingQuoteResponse,
    BookingResponse,
    BookingCancelRequest,
)
from app.services.booking_service import (
    calculate_quote,
    create_booking,
    cancel_booking,
)

router = APIRouter(prefix="/bookings", tags=["bookings"])


@router.post("/quote", response_model=BookingQuoteResponse)
def get_quote(
    req: BookingQuoteRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return calculate_quote(
        db=db,
        tenant_id=current_user.tenant_id,
        category_id=req.category_id,
        start_datetime=req.start_datetime,
        end_datetime=req.end_datetime,
        vehicle_id=req.vehicle_id,
        rate_plan_id=req.rate_plan_id,
        extras=req.extras,
    )


@router.post("", response_model=BookingResponse, status_code=status.HTTP_201_CREATED)
def make_booking(
    req: BookingCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return create_booking(
        db=db,
        tenant_id=current_user.tenant_id,
        data=req,
        created_by=current_user.id,
    )


@router.get("", response_model=list[BookingResponse])
def list_all_bookings(
    customer_id: uuid.UUID | None = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    query = select(Booking).where(Booking.tenant_id == current_user.tenant_id)
    if customer_id:
        query = query.where(Booking.customer_id == customer_id)
    query = query.order_by(Booking.created_at.desc())
    return list(db.execute(query).scalars().all())


@router.get("/{booking_id}", response_model=BookingResponse)
def get_single_booking(
    booking_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    booking = db.execute(
        select(Booking).where(
            Booking.id == booking_id,
            Booking.tenant_id == current_user.tenant_id,
        )
    ).scalar_one_or_none()

    if not booking:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found")

    return booking


@router.post("/{booking_id}/cancel", response_model=BookingResponse)
def cancel_single_booking(
    booking_id: uuid.UUID,
    req: BookingCancelRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return cancel_booking(
        db=db,
        tenant_id=current_user.tenant_id,
        booking_id=booking_id,
        cancel_req=req,
        user_id=current_user.id,
    )

