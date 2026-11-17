import uuid
from datetime import datetime, date, timedelta, timezone
from sqlalchemy.orm import Session
from sqlalchemy import select, and_, or_

from app.models.vehicle import Vehicle
from app.models.vehicle_category import VehicleCategory
from app.models.booking import Booking
from app.models.contract import Contract
from app.models.vehicle_availability import VehicleAvailabilityBlock
from app.models.work_order import WorkOrder
from app.models.vehicle_document import VehicleDocument
from app.core.enums import (
    VehicleStatus,
    BookingStatus,
    ContractStatus,
    WorkOrderStatus,
    VehicleDocumentType,
)


class AvailabilityService:
    def __init__(self, turnaround_buffer_minutes: int = 60):
        self.default_buffer = timedelta(minutes=turnaround_buffer_minutes)

    def check_vehicle_availability(
        self,
        db: Session,
        tenant_id: uuid.UUID,
        vehicle_id: uuid.UUID,
        start_datetime: datetime,
        end_datetime: datetime,
        exclude_booking_id: uuid.UUID | None = None,
        exclude_contract_id: uuid.UUID | None = None,
        buffer_minutes: int = 60,
    ) -> tuple[bool, str | None]:
        if end_datetime <= start_datetime:
            return False, "End datetime must be after start datetime"

        vehicle = db.execute(
            select(Vehicle).where(
                Vehicle.id == vehicle_id,
                Vehicle.tenant_id == tenant_id,
            )
        ).scalar_one_or_none()

        if not vehicle:
            return False, "Vehicle not found"

        if vehicle.status in [
            VehicleStatus.ACCIDENT,
            VehicleStatus.OUT_OF_SERVICE,
            VehicleStatus.SOLD_ARCHIVED,
        ]:
            return False, f"Vehicle is {vehicle.status.value}"

        buffer = timedelta(minutes=buffer_minutes)
        window_start = start_datetime - buffer
        window_end = end_datetime + buffer

        now_date = date.today()
        docs = db.execute(
            select(VehicleDocument).where(
                VehicleDocument.vehicle_id == vehicle_id,
                VehicleDocument.tenant_id == tenant_id,
            )
        ).scalars().all()

        for d in docs:
            if d.expiry_date and d.expiry_date < now_date:
                if d.document_type in [
                    VehicleDocumentType.INSURANCE,
                    VehicleDocumentType.INSPECTION,
                    VehicleDocumentType.REGISTRATION,
                ]:
                    return False, f"Expired {d.document_type.value} document ({d.document_number})"

        work_orders = db.execute(
            select(WorkOrder).where(
                WorkOrder.vehicle_id == vehicle_id,
                WorkOrder.tenant_id == tenant_id,
                WorkOrder.status.in_([WorkOrderStatus.SCHEDULED, WorkOrderStatus.IN_PROGRESS]),
                WorkOrder.start_date <= end_datetime.date(),
                or_(
                    WorkOrder.estimated_completion_date >= start_datetime.date(),
                    WorkOrder.estimated_completion_date.is_(None),
                ),
            )
        ).scalars().all()

        if work_orders:
            return False, "Vehicle is scheduled for maintenance during this period"

        block_stmt = select(VehicleAvailabilityBlock).where(
            VehicleAvailabilityBlock.vehicle_id == vehicle_id,
            VehicleAvailabilityBlock.tenant_id == tenant_id,
            VehicleAvailabilityBlock.status == "ACTIVE",
            VehicleAvailabilityBlock.start_time < window_end,
            VehicleAvailabilityBlock.end_time > window_start,
        )
        if exclude_booking_id:
            block_stmt = block_stmt.where(VehicleAvailabilityBlock.reference_id != exclude_booking_id)
        if exclude_contract_id:
            block_stmt = block_stmt.where(VehicleAvailabilityBlock.reference_id != exclude_contract_id)

        blocks = db.execute(block_stmt).scalars().all()
        if blocks:
            return False, f"Vehicle has active availability block: {blocks[0].block_type}"

        booking_stmt = select(Booking).where(
            Booking.vehicle_id == vehicle_id,
            Booking.tenant_id == tenant_id,
            Booking.status.in_([BookingStatus.CONFIRMED, BookingStatus.ACTIVE]),
            Booking.start_datetime < window_end,
            Booking.end_datetime > window_start,
        )
        if exclude_booking_id:
            booking_stmt = booking_stmt.where(Booking.id != exclude_booking_id)

        conflicting_booking = db.execute(booking_stmt).first()
        if conflicting_booking:
            return False, "Vehicle is already booked for an overlapping time window"

        contract_stmt = select(Contract).where(
            Contract.vehicle_id == vehicle_id,
            Contract.tenant_id == tenant_id,
            Contract.status == ContractStatus.ACTIVE,
            Contract.start_datetime < window_end,
            Contract.expected_return_datetime > window_start,
        )
        if exclude_contract_id:
            contract_stmt = contract_stmt.where(Contract.id != exclude_contract_id)

        conflicting_contract = db.execute(contract_stmt).first()
        if conflicting_contract:
            return False, "Vehicle is currently rented under an active contract"

        return True, None

    def search_available_vehicles(
        self,
        db: Session,
        tenant_id: uuid.UUID,
        start_datetime: datetime,
        end_datetime: datetime,
        branch_id: uuid.UUID | None = None,
        category_id: uuid.UUID | None = None,
        min_seats: int | None = None,
        min_payload_tonnes: float | None = None,
        buffer_minutes: int = 60,
    ) -> list[dict]:
        query = select(Vehicle, VehicleCategory).join(
            VehicleCategory, Vehicle.category_id == VehicleCategory.id
        ).where(
            Vehicle.tenant_id == tenant_id,
            Vehicle.status.in_([VehicleStatus.AVAILABLE, VehicleStatus.RESERVED]),
        )

        if branch_id:
            query = query.where(Vehicle.branch_id == branch_id)
        if category_id:
            query = query.where(Vehicle.category_id == category_id)
        if min_seats:
            query = query.where(VehicleCategory.seats >= min_seats)
        if min_payload_tonnes:
            query = query.where(VehicleCategory.payload_capacity_tonnes >= min_payload_tonnes)

        results = db.execute(query).all()
        available_vehicles = []

        for vehicle, category in results:
            is_avail, conflict = self.check_vehicle_availability(
                db=db,
                tenant_id=tenant_id,
                vehicle_id=vehicle.id,
                start_datetime=start_datetime,
                end_datetime=end_datetime,
                buffer_minutes=buffer_minutes,
            )
            available_vehicles.append({
                "vehicle_id": vehicle.id,
                "plate_number": vehicle.plate_number,
                "make": vehicle.make,
                "model": vehicle.model,
                "year": vehicle.year,
                "category_id": category.id,
                "category_name": category.name,
                "branch_id": vehicle.branch_id,
                "current_status": vehicle.status,
                "is_available": is_avail,
                "conflict_reason": conflict,
            })

        return available_vehicles

    def get_category_daily_capacity(
        self,
        db: Session,
        tenant_id: uuid.UUID,
        start_date: date,
        end_date: date,
        branch_id: uuid.UUID | None = None,
    ) -> list[dict]:
        categories = db.execute(
            select(VehicleCategory).where(VehicleCategory.tenant_id == tenant_id)
        ).scalars().all()

        daily_capacities = []
        curr = start_date
        while curr <= end_date:
            day_start = datetime.combine(curr, datetime.min.time(), tzinfo=timezone.utc)
            day_end = datetime.combine(curr, datetime.max.time(), tzinfo=timezone.utc)

            for cat in categories:
                v_query = select(Vehicle).where(
                    Vehicle.tenant_id == tenant_id,
                    Vehicle.category_id == cat.id,
                )
                if branch_id:
                    v_query = v_query.where(Vehicle.branch_id == branch_id)
                vehicles = db.execute(v_query).scalars().all()

                total = len(vehicles)
                avail_count = 0
                res_count = 0
                rented_count = 0
                maint_count = 0

                for v in vehicles:
                    if v.status in [VehicleStatus.UNDER_MAINTENANCE, VehicleStatus.ACCIDENT, VehicleStatus.OUT_OF_SERVICE]:
                        maint_count += 1
                        continue

                    is_free, _ = self.check_vehicle_availability(
                        db=db,
                        tenant_id=tenant_id,
                        vehicle_id=v.id,
                        start_datetime=day_start,
                        end_datetime=day_end,
                    )
                    if is_free:
                        avail_count += 1
                    elif v.status == VehicleStatus.RENTED:
                        rented_count += 1
                    else:
                        res_count += 1

                daily_capacities.append({
                    "category_id": cat.id,
                    "category_name": cat.name,
                    "date": curr,
                    "total_vehicles": total,
                    "available_vehicles": avail_count,
                    "reserved_vehicles": res_count,
                    "rented_vehicles": rented_count,
                    "maintenance_vehicles": maint_count,
                })
            curr += timedelta(days=1)

        return daily_capacities

    def create_availability_block(
        self,
        db: Session,
        tenant_id: uuid.UUID,
        vehicle_id: uuid.UUID,
        start_time: datetime,
        end_time: datetime,
        block_type: str,
        reference_id: uuid.UUID | None = None,
    ) -> VehicleAvailabilityBlock:
        block = VehicleAvailabilityBlock(
            tenant_id=tenant_id,
            vehicle_id=vehicle_id,
            start_time=start_time,
            end_time=end_time,
            block_type=block_type,
            reference_id=reference_id,
            status="ACTIVE",
        )
        db.add(block)
        db.flush()
        return block

    def release_availability_block(
        self,
        db: Session,
        tenant_id: uuid.UUID,
        reference_id: uuid.UUID,
    ) -> None:
        blocks = db.execute(
            select(VehicleAvailabilityBlock).where(
                VehicleAvailabilityBlock.tenant_id == tenant_id,
                VehicleAvailabilityBlock.reference_id == reference_id,
            )
        ).scalars().all()
        for b in blocks:
            b.status = "RELEASED"
        db.flush()


availability_service = AvailabilityService()
