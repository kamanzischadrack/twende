import uuid
from datetime import datetime, timezone, timedelta, date
from sqlalchemy.orm import Session
from sqlalchemy import select
from fastapi import HTTPException, status

from app.models.contract import Contract, ContractLine, ContractAmendment
from app.models.booking import Booking
from app.models.vehicle import Vehicle
from app.models.customer import Customer
from app.models.inspection import Inspection
from app.models.invoice import Invoice, InvoiceLine
from app.models.deposit import Deposit
from app.models.rate_plan import RatePlan
from app.core.enums import (
    ContractStatus,
    ContractLineType,
    BookingStatus,
    VehicleStatus,
    InspectionType,
    InvoiceType,
    InvoiceStatus,
    DepositStatus,
)
from app.schemas.contract import (
    ContractCreateFromBooking,
    HandoverRequest,
    ReturnRequest,
    ExtensionRequest,
    VehicleSwapRequest,
    AddChargeRequest,
)
from app.services.availability_service import availability_service
from app.services.pricing_service import get_applicable_rate_plan, calculate_rental_charge


def generate_contract_number() -> str:
    return f"CTR-{datetime.now(timezone.utc).strftime('%Y%m%d')}-{uuid.uuid4().hex[:6].upper()}"


def create_contract_from_booking(
    db: Session,
    tenant_id: uuid.UUID,
    data: ContractCreateFromBooking,
    user_id: uuid.UUID | None = None,
) -> Contract:
    booking = db.execute(
        select(Booking).where(
            Booking.id == data.booking_id,
            Booking.tenant_id == tenant_id,
        )
    ).scalar_one_or_none()

    if not booking:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found")

    if not booking.vehicle_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot generate contract: booking has no assigned vehicle",
        )

    vehicle = db.execute(
        select(Vehicle).where(
            Vehicle.id == booking.vehicle_id,
            Vehicle.tenant_id == tenant_id,
        )
    ).scalar_one_or_none()

    if not vehicle or vehicle.status not in [VehicleStatus.AVAILABLE, VehicleStatus.RESERVED]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Vehicle is not in rentable state (status: {vehicle.status.value if vehicle else 'Unknown'})",
        )

    contract_num = generate_contract_number()
    contract = Contract(
        tenant_id=tenant_id,
        contract_number=contract_num,
        booking_id=booking.id,
        customer_id=booking.customer_id,
        vehicle_id=booking.vehicle_id,
        assigned_driver_id=data.assigned_driver_id,
        pickup_branch_id=booking.pickup_branch_id,
        return_branch_id=booking.return_branch_id,
        start_datetime=booking.start_datetime,
        expected_return_datetime=booking.end_datetime,
        status=ContractStatus.DRAFT,
        terms=data.terms,
        created_by=user_id,
    )
    db.add(contract)
    db.flush()

    quote_total = float(booking.quoted_amount)
    subtotal = quote_total / 1.18
    tax_amt = quote_total - subtotal

    line = ContractLine(
        tenant_id=tenant_id,
        contract_id=contract.id,
        line_type=ContractLineType.RENTAL_CHARGE,
        description=f"Vehicle rental charge ({booking.booking_number})",
        quantity=1.0,
        unit_price=round(subtotal, 2),
        tax_rate=0.18,
        tax_amount=round(tax_amt, 2),
        total_amount=round(quote_total, 2),
    )
    db.add(line)

    booking.status = BookingStatus.ACTIVE
    db.commit()
    db.refresh(contract)
    return contract


def execute_handover(
    db: Session,
    tenant_id: uuid.UUID,
    contract_id: uuid.UUID,
    handover_data: HandoverRequest,
    user_id: uuid.UUID | None = None,
) -> Contract:
    contract = db.execute(
        select(Contract).where(
            Contract.id == contract_id,
            Contract.tenant_id == tenant_id,
        )
    ).scalar_one_or_none()

    if not contract:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Contract not found")

    if contract.status not in [ContractStatus.DRAFT, ContractStatus.ACTIVE]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Contract cannot be handed over with status {contract.status.value}",
        )

    vehicle = db.execute(
        select(Vehicle).where(
            Vehicle.id == contract.vehicle_id,
            Vehicle.tenant_id == tenant_id,
        )
    ).scalar_one_or_none()

    if not vehicle:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Vehicle not found")

    inspection = Inspection(
        tenant_id=tenant_id,
        vehicle_id=vehicle.id,
        contract_id=contract.id,
        inspection_type=InspectionType.HANDOVER,
        odometer_reading=handover_data.starting_mileage,
        fuel_fraction=handover_data.fuel_level,
        checklist_data=handover_data.checklist,
        photos=handover_data.photos,
        signature_url=handover_data.customer_signature_url,
    )
    db.add(inspection)

    vehicle.current_mileage = float(handover_data.starting_mileage)
    vehicle.status = VehicleStatus.RENTED

    contract.status = ContractStatus.ACTIVE
    contract.customer_signature_url = handover_data.customer_signature_url
    contract.staff_signature_url = handover_data.staff_signature_url
    contract.signed_at = datetime.now(timezone.utc)

    db.commit()
    db.refresh(contract)
    return contract


def add_contract_charge(
    db: Session,
    tenant_id: uuid.UUID,
    contract_id: uuid.UUID,
    charge_data: AddChargeRequest,
) -> ContractLine:
    contract = db.execute(
        select(Contract).where(
            Contract.id == contract_id,
            Contract.tenant_id == tenant_id,
        )
    ).scalar_one_or_none()

    if not contract:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Contract not found")

    subtotal = charge_data.quantity * charge_data.unit_price
    tax_amount = subtotal * charge_data.tax_rate
    total = subtotal + tax_amount

    line = ContractLine(
        tenant_id=tenant_id,
        contract_id=contract.id,
        line_type=charge_data.line_type,
        description=charge_data.description,
        quantity=charge_data.quantity,
        unit_price=charge_data.unit_price,
        tax_rate=charge_data.tax_rate,
        tax_amount=round(tax_amount, 2),
        total_amount=round(total, 2),
    )
    db.add(line)
    db.commit()
    db.refresh(line)
    return line


def extend_contract(
    db: Session,
    tenant_id: uuid.UUID,
    contract_id: uuid.UUID,
    extension_req: ExtensionRequest,
    user_id: uuid.UUID | None = None,
) -> Contract:
    contract = db.execute(
        select(Contract).where(
            Contract.id == contract_id,
            Contract.tenant_id == tenant_id,
        )
    ).scalar_one_or_none()

    if not contract:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Contract not found")

    if extension_req.new_expected_return <= contract.expected_return_datetime:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="New return time must be later than the current return time",
        )

    is_avail, reason = availability_service.check_vehicle_availability(
        db=db,
        tenant_id=tenant_id,
        vehicle_id=contract.vehicle_id,
        start_datetime=contract.expected_return_datetime,
        end_datetime=extension_req.new_expected_return,
        exclude_contract_id=contract.id,
    )
    if not is_avail:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Vehicle extension conflict: {reason}",
        )

    vehicle = db.execute(select(Vehicle).where(Vehicle.id == contract.vehicle_id)).scalar_one()
    rate_plan = get_applicable_rate_plan(db, tenant_id, vehicle.category_id, vehicle.id)
    daily_rate = float(rate_plan.daily_rate) if rate_plan else 50000.0

    extra_seconds = (extension_req.new_expected_return - contract.expected_return_datetime).total_seconds()
    extra_days = max(1, int((extra_seconds + 3599) // 86400))
    extra_charge = extra_days * daily_rate
    extra_tax = extra_charge * 0.18
    extra_total = extra_charge + extra_tax

    amendment = ContractAmendment(
        tenant_id=tenant_id,
        contract_id=contract.id,
        previous_expected_return=contract.expected_return_datetime,
        new_expected_return=extension_req.new_expected_return,
        additional_charge=extra_total,
        reason=extension_req.reason or "Rental extension",
        approved_by=user_id,
    )
    db.add(amendment)

    line = ContractLine(
        tenant_id=tenant_id,
        contract_id=contract.id,
        line_type=ContractLineType.RENTAL_CHARGE,
        description=f"Extension for {extra_days} day(s)",
        quantity=float(extra_days),
        unit_price=daily_rate,
        tax_rate=0.18,
        tax_amount=round(extra_tax, 2),
        total_amount=round(extra_total, 2),
    )
    db.add(line)

    contract.expected_return_datetime = extension_req.new_expected_return
    contract.status = ContractStatus.AMENDED

    db.commit()
    db.refresh(contract)
    return contract


def execute_return(
    db: Session,
    tenant_id: uuid.UUID,
    contract_id: uuid.UUID,
    return_data: ReturnRequest,
    user_id: uuid.UUID | None = None,
) -> Invoice:
    contract = db.execute(
        select(Contract).where(
            Contract.id == contract_id,
            Contract.tenant_id == tenant_id,
        )
    ).scalar_one_or_none()

    if not contract:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Contract not found")

    vehicle = db.execute(select(Vehicle).where(Vehicle.id == contract.vehicle_id)).scalar_one()

    handover_inspection = db.execute(
        select(Inspection).where(
            Inspection.contract_id == contract.id,
            Inspection.inspection_type == InspectionType.HANDOVER,
        )
    ).scalar_one_or_none()

    start_km = handover_inspection.odometer_reading if handover_inspection else int(vehicle.current_mileage)
    if return_data.final_mileage < start_km:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Final mileage ({return_data.final_mileage} km) cannot be lower than handover mileage ({start_km} km)",
        )

    ret_inspection = Inspection(
        tenant_id=tenant_id,
        vehicle_id=vehicle.id,
        contract_id=contract.id,
        inspection_type=InspectionType.RETURN,
        odometer_reading=return_data.final_mileage,
        fuel_fraction=return_data.fuel_level,
        checklist_data=return_data.checklist,
        photos=return_data.photos,
        signature_url=return_data.customer_signature_url,
    )
    db.add(ret_inspection)

    rate_plan = get_applicable_rate_plan(db, tenant_id, vehicle.category_id, vehicle.id)
    rate_plan_daily = float(rate_plan.daily_rate) if rate_plan else 50000.0
    rate_plan_excess_km = float(rate_plan.excess_km_rate) if rate_plan and rate_plan.excess_km_rate else 150.0
    daily_km_allowance = rate_plan.included_km_per_day if rate_plan and rate_plan.included_km_per_day else 200

    duration_days = max(1, (contract.expected_return_datetime - contract.start_datetime).days)
    total_allowed_km = duration_days * daily_km_allowance
    actual_km = return_data.final_mileage - start_km
    excess_km = max(0, actual_km - total_allowed_km)

    if excess_km > 0:
        excess_amt = excess_km * rate_plan_excess_km
        excess_tax = excess_amt * 0.18
        db.add(ContractLine(
            tenant_id=tenant_id,
            contract_id=contract.id,
            line_type=ContractLineType.EXCESS_KM,
            description=f"Excess mileage ({excess_km} km @ {rate_plan_excess_km} RWF/km)",
            quantity=float(excess_km),
            unit_price=rate_plan_excess_km,
            tax_rate=0.18,
            tax_amount=round(excess_tax, 2),
            total_amount=round(excess_amt + excess_tax, 2),
        ))

    start_fuel = float(handover_inspection.fuel_fraction) if handover_inspection else 1.0
    if return_data.fuel_level < start_fuel:
        shortage_fraction = start_fuel - return_data.fuel_level
        litres = shortage_fraction * 60.0
        fuel_rate = 1800.0
        fuel_amt = (litres * fuel_rate) + 5000.0
        fuel_tax = fuel_amt * 0.18
        db.add(ContractLine(
            tenant_id=tenant_id,
            contract_id=contract.id,
            line_type=ContractLineType.FUEL_SHORTAGE,
            description=f"Fuel shortage ({round(litres, 1)} L + refuel fee)",
            quantity=1.0,
            unit_price=round(fuel_amt, 2),
            tax_rate=0.18,
            tax_amount=round(fuel_tax, 2),
            total_amount=round(fuel_amt + fuel_tax, 2),
        ))

    if return_data.return_datetime > contract.expected_return_datetime:
        grace_mins = rate_plan.grace_period_minutes if rate_plan else 60
        late_secs = (return_data.return_datetime - contract.expected_return_datetime).total_seconds()
        late_mins = late_secs / 60.0
        if late_mins > grace_mins:
            late_hours = max(1, int((late_secs + 3599) // 3600))
            hourly_rate = rate_plan_daily / 10.0
            late_charge = min(rate_plan_daily, late_hours * hourly_rate)
            late_tax = late_charge * 0.18
            db.add(ContractLine(
                tenant_id=tenant_id,
                contract_id=contract.id,
                line_type=ContractLineType.LATE_RETURN,
                description=f"Late return fee ({late_hours} hours beyond grace period)",
                quantity=1.0,
                unit_price=round(late_charge, 2),
                tax_rate=0.18,
                tax_amount=round(late_tax, 2),
                total_amount=round(late_charge + late_tax, 2),
            ))

    if return_data.cleaning_fee > 0:
        c_amt = return_data.cleaning_fee
        c_tax = c_amt * 0.18
        db.add(ContractLine(
            tenant_id=tenant_id,
            contract_id=contract.id,
            line_type=ContractLineType.CLEANING,
            description="Vehicle cleaning fee",
            quantity=1.0,
            unit_price=c_amt,
            tax_rate=0.18,
            tax_amount=round(c_tax, 2),
            total_amount=round(c_amt + c_tax, 2),
        ))

    if return_data.damage_fee > 0:
        d_amt = return_data.damage_fee
        d_tax = d_amt * 0.18
        db.add(ContractLine(
            tenant_id=tenant_id,
            contract_id=contract.id,
            line_type=ContractLineType.DAMAGE,
            description="Vehicle damage fee assessed upon return",
            quantity=1.0,
            unit_price=d_amt,
            tax_rate=0.18,
            tax_amount=round(d_tax, 2),
            total_amount=round(d_amt + d_tax, 2),
        ))

    vehicle.current_mileage = float(return_data.final_mileage)
    vehicle.status = VehicleStatus.UNDER_INSPECTION

    contract.status = ContractStatus.RETURNED
    contract.actual_return_datetime = return_data.return_datetime

    availability_service.release_availability_block(db, tenant_id, contract.id)
    if contract.booking_id:
        availability_service.release_availability_block(db, tenant_id, contract.booking_id)

    db.flush()

    contract_lines = db.execute(
        select(ContractLine).where(
            ContractLine.contract_id == contract.id,
            ContractLine.tenant_id == tenant_id,
        )
    ).scalars().all()

    subtotal = sum(float(l.quantity) * float(l.unit_price) for l in contract_lines)
    tax_total = sum(float(l.tax_amount) for l in contract_lines)
    grand_total = sum(float(l.total_amount) for l in contract_lines)

    deposit = db.execute(
        select(Deposit).where(
            Deposit.contract_id == contract.id,
            Deposit.tenant_id == tenant_id,
            Deposit.status == DepositStatus.HELD,
        )
    ).scalar_one_or_none()

    deposit_held = float(deposit.held_amount) if deposit else 0.0
    deposit_to_apply = min(deposit_held, grand_total)
    balance_due = max(0.0, grand_total - deposit_to_apply)

    if deposit and deposit_to_apply > 0:
        deposit.applied_amount = deposit_to_apply
        deposit.held_amount = deposit_held - deposit_to_apply
        if deposit.held_amount == 0.0:
            deposit.status = DepositStatus.APPLIED

    invoice_num = f"INV-{datetime.now(timezone.utc).strftime('%Y%m%d')}-{uuid.uuid4().hex[:6].upper()}"
    invoice = Invoice(
        tenant_id=tenant_id,
        invoice_number=invoice_num,
        customer_id=contract.customer_id,
        contract_id=contract.id,
        invoice_type=InvoiceType.INVOICE,
        issue_date=date.today(),
        subtotal=round(subtotal, 2),
        tax_total=round(tax_total, 2),
        grand_total=round(grand_total, 2),
        paid_amount=round(deposit_to_apply, 2),
        balance_due=round(balance_due, 2),
        status=InvoiceStatus.PAID if balance_due == 0.0 else InvoiceStatus.ISSUED,
        ebm_status="CERTIFIED",
        ebm_reference=f"RRA-{uuid.uuid4().hex[:10].upper()}",
    )
    db.add(invoice)
    db.flush()

    for l in contract_lines:
        inv_line = InvoiceLine(
            tenant_id=tenant_id,
            invoice_id=invoice.id,
            line_type=l.line_type.value,
            description=l.description,
            quantity=l.quantity,
            unit_price=l.unit_price,
            tax_rate=l.tax_rate,
            tax_amount=l.tax_amount,
            line_total=l.total_amount,
        )
        db.add(inv_line)

    db.commit()
    db.refresh(invoice)
    return invoice
