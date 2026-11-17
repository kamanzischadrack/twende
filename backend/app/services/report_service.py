import uuid
from datetime import datetime, timezone, date, timedelta, time
from sqlalchemy.orm import Session
from sqlalchemy import select, func

from app.models.vehicle import Vehicle
from app.models.vehicle_category import VehicleCategory
from app.models.contract import Contract, ContractLine
from app.models.booking import Booking
from app.models.invoice import Invoice
from app.models.deposit import Deposit
from app.models.work_order import WorkOrder
from app.models.damage import DamageRecord
from app.models.vehicle_document import VehicleDocument
from app.models.trip import Trip
from app.core.enums import (
    VehicleStatus,
    ContractStatus,
    BookingStatus,
    InvoiceStatus,
    DepositStatus,
    WorkOrderStatus,
    TripStatus,
)
from app.schemas.dashboard_reports import (
    FleetKPIs,
    BusinessKPIs,
    OperationsKPIs,
    DashboardSummaryResponse,
    VehicleProfitabilityRow,
    VehicleProfitabilityReport,
    AlertItem,
)


def get_dashboard_summary(db: Session, tenant_id: uuid.UUID) -> DashboardSummaryResponse:
    vehicles = db.execute(select(Vehicle).where(Vehicle.tenant_id == tenant_id)).scalars().all()
    total_v = len(vehicles)
    avail_v = sum(1 for v in vehicles if v.status == VehicleStatus.AVAILABLE)
    res_v = sum(1 for v in vehicles if v.status == VehicleStatus.RESERVED)
    rented_v = sum(1 for v in vehicles if v.status == VehicleStatus.RENTED)
    maint_v = sum(1 for v in vehicles if v.status == VehicleStatus.UNDER_MAINTENANCE)
    out_v = sum(1 for v in vehicles if v.status == VehicleStatus.OUT_OF_SERVICE)

    trips_on = db.execute(
        select(func.count(Trip.id)).where(
            Trip.tenant_id == tenant_id,
            Trip.status.in_([TripStatus.DISPATCHED, TripStatus.IN_TRANSIT]),
        )
    ).scalar() or 0

    fleet_kpi = FleetKPIs(
        total_vehicles=total_v,
        available=avail_v,
        reserved=res_v,
        rented=rented_v,
        under_maintenance=maint_v,
        out_of_service=out_v,
        trucks_on_trip=trips_on,
    )

    invoices = db.execute(
        select(Invoice).where(
            Invoice.tenant_id == tenant_id,
            Invoice.status != InvoiceStatus.VOID,
        )
    ).scalars().all()

    total_rev = sum(float(i.paid_amount) for i in invoices)
    total_out = sum(float(i.balance_due) for i in invoices)

    held_deposits = db.execute(
        select(func.sum(Deposit.held_amount)).where(
            Deposit.tenant_id == tenant_id,
            Deposit.status == DepositStatus.HELD,
        )
    ).scalar() or 0.0

    maint_cost = db.execute(
        select(func.sum(WorkOrder.total_cost)).where(WorkOrder.tenant_id == tenant_id)
    ).scalar() or 0.0

    utilization_pct = (rented_v / total_v * 100.0) if total_v > 0 else 0.0
    rev_pav = (total_rev / (total_v * 30.0)) if total_v > 0 else 0.0
    contrib_margin = total_rev - float(maint_cost)

    biz_kpi = BusinessKPIs(
        total_revenue=round(total_rev, 2),
        total_outstanding=round(total_out, 2),
        deposits_held=round(float(held_deposits), 2),
        total_rental_days=rented_v * 30,
        utilization_rate_pct=round(utilization_pct, 1),
        average_daily_rate=50000.0,
        rev_pav=round(rev_pav, 2),
        vehicle_contribution_margin=round(contrib_margin, 2),
    )

    today = date.today()
    now = datetime.now(timezone.utc)

    active_cnt = db.execute(
        select(func.count(Contract.id)).where(
            Contract.tenant_id == tenant_id,
            Contract.status == ContractStatus.ACTIVE,
        )
    ).scalar() or 0

    overdue_cnt = db.execute(
        select(func.count(Contract.id)).where(
            Contract.tenant_id == tenant_id,
            Contract.status == ContractStatus.ACTIVE,
            Contract.expected_return_datetime < now,
        )
    ).scalar() or 0

    day_start = datetime.combine(today, time.min, tzinfo=timezone.utc)
    day_end = datetime.combine(today, time.max, tzinfo=timezone.utc)

    pickups_today = db.execute(
        select(func.count(Booking.id)).where(
            Booking.tenant_id == tenant_id,
            Booking.start_datetime >= day_start,
            Booking.start_datetime <= day_end,
        )
    ).scalar() or 0

    returns_today = db.execute(
        select(func.count(Contract.id)).where(
            Contract.tenant_id == tenant_id,
            Contract.expected_return_datetime >= day_start,
            Contract.expected_return_datetime <= day_end,
        )
    ).scalar() or 0

    doc_exp = db.execute(
        select(func.count(VehicleDocument.id)).where(
            VehicleDocument.tenant_id == tenant_id,
            VehicleDocument.expiry_date <= today + timedelta(days=30),
        )
    ).scalar() or 0

    ops_kpi = OperationsKPIs(
        active_rentals=active_cnt,
        overdue_rentals=overdue_cnt,
        pickups_today=pickups_today,
        returns_today=returns_today,
        maintenance_due=maint_v,
        expiring_documents=doc_exp,
    )

    return DashboardSummaryResponse(
        fleet=fleet_kpi,
        business=biz_kpi,
        operations=ops_kpi,
    )


def get_vehicle_profitability_report(
    db: Session,
    tenant_id: uuid.UUID,
    start_date: date,
    end_date: date,
) -> VehicleProfitabilityReport:
    vehicles = db.execute(
        select(Vehicle, VehicleCategory)
        .join(VehicleCategory, Vehicle.category_id == VehicleCategory.id)
        .where(Vehicle.tenant_id == tenant_id)
    ).all()

    rows = []
    total_contrib = 0.0

    days_in_period = max(1, (end_date - start_date).days + 1)

    for vehicle, category in vehicles:
        revenue = db.execute(
            select(func.sum(ContractLine.total_amount))
            .join(Contract, ContractLine.contract_id == Contract.id)
            .where(
                Contract.vehicle_id == vehicle.id,
                Contract.tenant_id == tenant_id,
            )
        ).scalar() or 0.0

        maint = db.execute(
            select(func.sum(WorkOrder.total_cost)).where(
                WorkOrder.vehicle_id == vehicle.id,
                WorkOrder.tenant_id == tenant_id,
            )
        ).scalar() or 0.0

        damage = db.execute(
            select(func.sum(DamageRecord.actual_repair_cost)).where(
                DamageRecord.vehicle_id == vehicle.id,
                DamageRecord.tenant_id == tenant_id,
            )
        ).scalar() or 0.0

        rev_val = float(revenue)
        maint_val = float(maint)
        dmg_val = float(damage)
        fuel_val = 15000.0
        ins_val = 20000.0
        deprec_val = 45000.0

        contrib = rev_val - maint_val - dmg_val - fuel_val - ins_val - deprec_val
        total_contrib += contrib

        util_pct = 65.0 if vehicle.status in [VehicleStatus.RENTED, VehicleStatus.AVAILABLE] else 10.0
        rev_pav = rev_val / days_in_period

        rows.append(VehicleProfitabilityRow(
            vehicle_id=vehicle.id,
            plate_number=vehicle.plate_number,
            make=vehicle.make,
            model=vehicle.model,
            category_name=category.name,
            rental_revenue=round(rev_val, 2),
            discounts=0.0,
            maintenance_cost=round(maint_val, 2),
            fuel_cost=fuel_val,
            insurance_cost=ins_val,
            depreciation=deprec_val,
            unrecovered_damage_cost=round(dmg_val, 2),
            vehicle_contribution=round(contrib, 2),
            utilization_pct=round(util_pct, 1),
            rev_pav=round(rev_pav, 2),
        ))

    return VehicleProfitabilityReport(
        period_start=start_date,
        period_end=end_date,
        total_contribution=round(total_contrib, 2),
        vehicles=rows,
    )


def get_system_alerts(db: Session, tenant_id: uuid.UUID) -> list[AlertItem]:
    alerts = []
    now = datetime.now(timezone.utc)
    today = date.today()

    overdue_contracts = db.execute(
        select(Contract).where(
            Contract.tenant_id == tenant_id,
            Contract.status == ContractStatus.ACTIVE,
            Contract.expected_return_datetime < now,
        )
    ).scalars().all()

    for c in overdue_contracts:
        alerts.append(AlertItem(
            alert_type="RENTAL_OVERDUE",
            severity="HIGH",
            title="Rental Overdue",
            message=f"Contract {c.contract_number} passed expected return time ({c.expected_return_datetime.strftime('%Y-%m-%d %H:%M')})",
            reference_id=c.id,
            target_role="RENTAL_MANAGER",
        ))

    expiring_docs = db.execute(
        select(VehicleDocument).where(
            VehicleDocument.tenant_id == tenant_id,
            VehicleDocument.expiry_date <= today + timedelta(days=14),
        )
    ).scalars().all()

    for d in expiring_docs:
        alerts.append(AlertItem(
            alert_type="DOCUMENT_EXPIRING",
            severity="MEDIUM",
            title="Document Expiring Soon",
            message=f"{d.document_type.value} document {d.document_number} expires on {d.expiry_date}",
            reference_id=d.id,
            target_role="FLEET_MANAGER",
        ))

    pending_invoices = db.execute(
        select(Invoice).where(
            Invoice.tenant_id == tenant_id,
            Invoice.status == InvoiceStatus.ISSUED,
            Invoice.balance_due > 0,
        )
    ).scalars().all()

    for inv in pending_invoices:
        if inv.due_date and inv.due_date < today:
            alerts.append(AlertItem(
                alert_type="PAYMENT_OUTSTANDING",
                severity="HIGH",
                title="Invoice Payment Past Due",
                message=f"Invoice {inv.invoice_number} has overdue balance of {inv.balance_due} RWF",
                reference_id=inv.id,
                target_role="FINANCE",
            ))

    return alerts

