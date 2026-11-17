import uuid
from datetime import datetime, timezone
from sqlalchemy.orm import Session
from sqlalchemy import select, func
from fastapi import HTTPException, status

from app.models.trip import Trip, TripStop, TripCost, ProofOfDelivery
from app.models.vehicle import Vehicle
from app.models.vehicle_category import VehicleCategory
from app.models.driver import Driver, DriverAssignment
from app.models.customer import Customer
from app.core.enums import TripStatus, DriverStatus, AssignmentStatus
from app.schemas.trip import TripCreate, TripCostCreate, ProofOfDeliveryCreate


def create_trip(
    db: Session,
    tenant_id: uuid.UUID,
    data: TripCreate,
    user_id: uuid.UUID | None = None,
) -> Trip:
    truck = db.execute(
        select(Vehicle).where(
            Vehicle.id == data.truck_id,
            Vehicle.tenant_id == tenant_id,
        )
    ).scalar_one_or_none()

    if not truck:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Truck not found")

    category = db.execute(select(VehicleCategory).where(VehicleCategory.id == truck.category_id)).scalar_one_or_none()
    max_payload = float(category.payload_capacity_tonnes) if category and category.payload_capacity_tonnes else 30.0
    if data.cargo_weight_tonnes > max_payload:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cargo weight ({data.cargo_weight_tonnes} tonnes) exceeds truck payload capacity ({max_payload} tonnes)",
        )

    if data.driver_id:
        driver = db.execute(
            select(Driver).where(
                Driver.id == data.driver_id,
                Driver.tenant_id == tenant_id,
            )
        ).scalar_one_or_none()

        if not driver:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Driver not found")

        active_assignment = db.execute(
            select(DriverAssignment).where(
                DriverAssignment.driver_id == data.driver_id,
                DriverAssignment.tenant_id == tenant_id,
                DriverAssignment.status == AssignmentStatus.ACTIVE,
            )
        ).first()

        if active_assignment:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Driver is already on an active assignment",
            )

    trip_num = f"TRP-{datetime.now(timezone.utc).strftime('%Y%m%d')}-{uuid.uuid4().hex[:6].upper()}"

    trip = Trip(
        tenant_id=tenant_id,
        trip_number=trip_num,
        truck_id=data.truck_id,
        trailer_id=data.trailer_id,
        driver_id=data.driver_id,
        customer_id=data.customer_id,
        origin=data.origin,
        destination=data.destination,
        cargo_type=data.cargo_type,
        cargo_weight_tonnes=data.cargo_weight_tonnes,
        cargo_volume_m3=data.cargo_volume_m3,
        revenue=data.revenue,
        planned_start=data.planned_start,
        planned_end=data.planned_end,
        status=TripStatus.DISPATCHED,
        created_by=user_id,
    )
    db.add(trip)
    db.flush()

    for s in data.stops:
        stop = TripStop(
            tenant_id=tenant_id,
            trip_id=trip.id,
            stop_order=s.stop_order,
            location_name=s.location_name,
            arrival_time=s.planned_arrival,
        )
        db.add(stop)

    if data.driver_id:
        assignment = DriverAssignment(
            tenant_id=tenant_id,
            driver_id=data.driver_id,
            trip_id=trip.id,
            start_datetime=data.planned_start,
            end_datetime=data.planned_end,
            rate_applied=driver.daily_rate,
            status=AssignmentStatus.ACTIVE,
        )
        db.add(assignment)

    db.commit()
    db.refresh(trip)
    return trip


def add_trip_cost(
    db: Session,
    tenant_id: uuid.UUID,
    trip_id: uuid.UUID,
    data: TripCostCreate,
) -> TripCost:
    trip = db.execute(
        select(Trip).where(
            Trip.id == trip_id,
            Trip.tenant_id == tenant_id,
        )
    ).scalar_one_or_none()

    if not trip:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Trip not found")

    cost = TripCost(
        tenant_id=tenant_id,
        trip_id=trip.id,
        cost_type=data.cost_type,
        amount=data.amount,
        currency=data.currency,
        receipt_photo_url=data.receipt_photo_url,
        notes=data.notes,
    )
    db.add(cost)
    db.commit()
    db.refresh(cost)
    return cost


def record_proof_of_delivery(
    db: Session,
    tenant_id: uuid.UUID,
    trip_id: uuid.UUID,
    data: ProofOfDeliveryCreate,
) -> ProofOfDelivery:
    trip = db.execute(
        select(Trip).where(
            Trip.id == trip_id,
            Trip.tenant_id == tenant_id,
        )
    ).scalar_one_or_none()

    if not trip:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Trip not found")

    pod = ProofOfDelivery(
        tenant_id=tenant_id,
        trip_id=trip.id,
        recipient_name=data.recipient_name,
        signature_url=data.signature_url,
        delivery_photo_url=data.delivery_photo_url,
        delivered_at=data.delivered_at,
        gps_latitude=data.gps_latitude,
        gps_longitude=data.gps_longitude,
    )
    db.add(pod)

    trip.status = TripStatus.DELIVERED
    trip.actual_end = data.delivered_at

    db.commit()
    db.refresh(pod)
    return pod


def close_trip(
    db: Session,
    tenant_id: uuid.UUID,
    trip_id: uuid.UUID,
) -> dict:
    trip = db.execute(
        select(Trip).where(
            Trip.id == trip_id,
            Trip.tenant_id == tenant_id,
        )
    ).scalar_one_or_none()

    if not trip:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Trip not found")

    total_cost = db.execute(
        select(func.sum(TripCost.amount)).where(
            TripCost.trip_id == trip.id,
            TripCost.tenant_id == tenant_id,
        )
    ).scalar() or 0.0

    margin = float(trip.revenue) - float(total_cost)
    trip.status = TripStatus.CLOSED

    if trip.driver_id:
        assignments = db.execute(
            select(DriverAssignment).where(
                DriverAssignment.trip_id == trip.id,
                DriverAssignment.tenant_id == tenant_id,
            )
        ).scalars().all()
        for a in assignments:
            a.status = AssignmentStatus.COMPLETED

    db.commit()

    return {
        "trip_id": trip.id,
        "trip_number": trip.trip_number,
        "revenue": float(trip.revenue),
        "total_cost": float(total_cost),
        "margin": float(margin),
        "status": trip.status.value,
    }
