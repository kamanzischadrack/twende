import uuid
from datetime import datetime, timezone, date
from sqlalchemy.orm import Session
from sqlalchemy import select
from fastapi import HTTPException, status

from app.models.booking import Booking
from app.models.customer import Customer
from app.models.vehicle import Vehicle
from app.models.vehicle_category import VehicleCategory
from app.models.tax_discount import TaxRate, Discount
from app.core.enums import (
    BookingStatus,
    BookingSource,
    RentalType,
    RiskStatus,
    VehicleStatus,
)
from app.schemas.booking import (
    BookingCreate,
    BookingQuoteRequest,
    BookingQuoteResponse,
    BookingCancelRequest,
)
from app.services.pricing_service import (
    get_applicable_rate_plan,
    calculate_rental_charge,
)
from app.services.availability_service import availability_service


def calculate_quote(
    db: Session,
    tenant_id: uuid.UUID,
    category_id: uuid.UUID,
    start_datetime: datetime,
    end_datetime: datetime,
    vehicle_id: uuid.UUID | None = None,
    rate_plan_id: uuid.UUID | None = None,
    extras: list | None = None,
    discount_amount: float = 0.0,
    required_deposit: float = 50000.0,
) -> BookingQuoteResponse:
    if end_datetime <= start_datetime:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="End time must be after start time",
        )

    rate_plan = get_applicable_rate_plan(db, tenant_id, category_id, vehicle_id)
    if not rate_plan:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No applicable rate plan found for this category or vehicle",
        )

    duration_seconds = (end_datetime - start_datetime).total_seconds()
    duration_hours = max(1.0, duration_seconds / 3600.0)
    duration_days = duration_seconds / 86400.0

    rental_charge = calculate_rental_charge(
        duration_hours=duration_hours,
        hourly_rate=float(rate_plan.hourly_rate) if rate_plan.hourly_rate else None,
        daily_rate=float(rate_plan.daily_rate),
        weekly_rate=float(rate_plan.weekly_rate) if rate_plan.weekly_rate else None,
        monthly_rate=float(rate_plan.monthly_rate) if rate_plan.monthly_rate else None,
        grace_period_mins=rate_plan.grace_period_minutes,
    )

    extras_total = 0.0
    if extras:
        for ext in extras:
            qty = getattr(ext, "quantity", 1.0)
            price = getattr(ext, "unit_price", 0.0)
            extras_total += float(qty) * float(price)

    subtotal_before_discount = rental_charge + extras_total
    applied_discount = min(discount_amount, subtotal_before_discount)
    subtotal = subtotal_before_discount - applied_discount

    tax_rate_record = db.execute(
        select(TaxRate).where(
            TaxRate.tenant_id == tenant_id,
            TaxRate.is_default.is_(True),
            TaxRate.is_active.is_(True),
        )
    ).scalar_one_or_none()

    tax_rate = float(tax_rate_record.rate) if tax_rate_record else 0.18
    is_inclusive = tax_rate_record.is_inclusive if tax_rate_record else False

    if is_inclusive:
        tax_amount = subtotal - (subtotal / (1.0 + tax_rate))
        grand_total = subtotal
    else:
        tax_amount = subtotal * tax_rate
        grand_total = subtotal + tax_amount

    return BookingQuoteResponse(
        duration_hours=round(duration_hours, 2),
        duration_days=round(duration_days, 2),
        rental_charge=round(rental_charge, 2),
        extras_total=round(extras_total, 2),
        discount_total=round(applied_discount, 2),
        subtotal=round(subtotal, 2),
        tax_rate=tax_rate,
        tax_amount=round(tax_amount, 2),
        grand_total=round(grand_total, 2),
        deposit_required=required_deposit,
    )


def create_booking(
    db: Session,
    tenant_id: uuid.UUID,
    data: BookingCreate,
    created_by: uuid.UUID | None = None,
) -> Booking:
    customer = db.execute(
        select(Customer).where(
            Customer.id == data.customer_id,
            Customer.tenant_id == tenant_id,
        )
    ).scalar_one_or_none()
    if not customer:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Customer not found")

    if customer.risk_status == RiskStatus.BLACKLISTED:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Customer is blacklisted and cannot create a booking",
        )

    if customer.licence_expiry_date and customer.licence_expiry_date < data.end_datetime.date():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Customer driving licence expires before rental return date",
        )

    quote = calculate_quote(
        db=db,
        tenant_id=tenant_id,
        category_id=data.category_id,
        start_datetime=data.start_datetime,
        end_datetime=data.end_datetime,
        vehicle_id=data.vehicle_id,
        rate_plan_id=data.rate_plan_id,
        extras=data.extras,
        discount_amount=data.discount_amount,
        required_deposit=data.required_deposit,
    )

    if data.vehicle_id:
        is_free, reason = availability_service.check_vehicle_availability(
            db=db,
            tenant_id=tenant_id,
            vehicle_id=data.vehicle_id,
            start_datetime=data.start_datetime,
            end_datetime=data.end_datetime,
        )
        if not is_free:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Vehicle conflict: {reason}",
            )

    booking_num = f"BK-{datetime.now(timezone.utc).strftime('%Y%m%d')}-{uuid.uuid4().hex[:6].upper()}"

    booking = Booking(
        tenant_id=tenant_id,
        booking_number=booking_num,
        customer_id=data.customer_id,
        category_id=data.category_id,
        vehicle_id=data.vehicle_id,
        pickup_branch_id=data.pickup_branch_id,
        return_branch_id=data.return_branch_id or data.pickup_branch_id,
        rental_type=data.rental_type,
        start_datetime=data.start_datetime,
        end_datetime=data.end_datetime,
        status=BookingStatus.CONFIRMED if data.vehicle_id else BookingStatus.PENDING,
        source=data.source,
        quoted_amount=quote.grand_total,
        notes=data.notes,
        created_by=created_by,
    )
    db.add(booking)
    db.flush()

    if data.vehicle_id:
        availability_service.create_availability_block(
            db=db,
            tenant_id=tenant_id,
            vehicle_id=data.vehicle_id,
            start_time=data.start_datetime,
            end_time=data.end_datetime,
            block_type="BOOKING",
            reference_id=booking.id,
        )

    db.commit()
    db.refresh(booking)
    return booking


def cancel_booking(
    db: Session,
    tenant_id: uuid.UUID,
    booking_id: uuid.UUID,
    cancel_req: BookingCancelRequest,
    user_id: uuid.UUID | None = None,
) -> Booking:
    booking = db.execute(
        select(Booking).where(
            Booking.id == booking_id,
            Booking.tenant_id == tenant_id,
        )
    ).scalar_one_or_none()

    if not booking:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found")

    if booking.status in [BookingStatus.CANCELLED, BookingStatus.COMPLETED]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot cancel booking with status {booking.status.value}",
        )

    booking.status = BookingStatus.CANCELLED
    availability_service.release_availability_block(db, tenant_id, booking.id)

    db.commit()
    db.refresh(booking)
    return booking
