import uuid
from datetime import datetime, timezone, time
from sqlalchemy.orm import Session
from sqlalchemy import select
from fastapi import HTTPException, status

from app.models.damage import DamageRecord
from app.models.incident import Incident
from app.models.contract import Contract, ContractLine
from app.models.approval import Approval
from app.core.enums import (
    DamageStatus,
    DamageLiability,
    IncidentStatus,
    ContractLineType,
    ApprovalDecision,
)
from app.schemas.damage_incident import (
    DamageRecordCreate,
    DamageRecordUpdate,
    IncidentCreate,
)


def create_damage_record(
    db: Session,
    tenant_id: uuid.UUID,
    data: DamageRecordCreate,
    user_id: uuid.UUID | None = None,
) -> DamageRecord:
    record = DamageRecord(
        tenant_id=tenant_id,
        vehicle_id=data.vehicle_id,
        contract_id=data.contract_id,
        customer_id=data.customer_id,
        discovery_date=data.discovery_date,
        damage_type=data.damage_type,
        location_on_vehicle=data.location_on_vehicle,
        severity=data.severity,
        photos=data.photos,
        estimated_repair_cost=data.estimated_repair_cost,
        actual_repair_cost=0.0,
        liability=data.liability,
        status=DamageStatus.REPORTED,
        created_by=user_id,
    )
    db.add(record)
    db.flush()

    if data.estimated_repair_cost > 100000.0 and data.liability == DamageLiability.CUSTOMER:
        approval = Approval(
            tenant_id=tenant_id,
            target_type="DAMAGE_CHARGE",
            target_id=record.id,
            requested_by_id=user_id or uuid.uuid4(),
            decision=ApprovalDecision.PENDING,
            reason=f"Damage charge of {data.estimated_repair_cost} RWF exceeds approval limit",
        )
        db.add(approval)

    db.commit()
    db.refresh(record)
    return record


def record_incident(
    db: Session,
    tenant_id: uuid.UUID,
    data: IncidentCreate,
    user_id: uuid.UUID | None = None,
) -> Incident:
    contract_id = data.contract_id
    driver_id = data.driver_id

    if not contract_id:
        day_start = datetime.combine(data.incident_date, time.min, tzinfo=timezone.utc)
        day_end = datetime.combine(data.incident_date, time.max, tzinfo=timezone.utc)

        active_contract = db.execute(
            select(Contract).where(
                Contract.vehicle_id == data.vehicle_id,
                Contract.tenant_id == tenant_id,
                Contract.start_datetime <= day_end,
                Contract.expected_return_datetime >= day_start,
            )
        ).scalar_one_or_none()

        if active_contract:
            contract_id = active_contract.id
            if not driver_id:
                driver_id = active_contract.assigned_driver_id

    inc_num = f"INC-{datetime.now(timezone.utc).strftime('%Y%m%d')}-{uuid.uuid4().hex[:6].upper()}"

    incident = Incident(
        tenant_id=tenant_id,
        incident_number=inc_num,
        vehicle_id=data.vehicle_id,
        contract_id=contract_id,
        driver_id=driver_id,
        incident_type=data.incident_type,
        incident_date=data.incident_date,
        location=data.location,
        evidence_url=data.evidence_url,
        police_report_number=data.police_report_number,
        fine_amount=data.fine_amount,
        is_recharged_to_customer=data.is_recharged_to_customer,
        status=IncidentStatus.REPORTED,
        resolution_notes=data.resolution_notes,
        created_by=user_id,
    )
    db.add(incident)
    db.flush()

    if data.is_recharged_to_customer and contract_id and data.fine_amount > 0:
        line = ContractLine(
            tenant_id=tenant_id,
            contract_id=contract_id,
            line_type=ContractLineType.FINE_RECHARGE,
            description=f"Traffic fine recharge ({incident.incident_number}): {data.location}",
            quantity=1.0,
            unit_price=data.fine_amount,
            tax_rate=0.0,
            tax_amount=0.0,
            total_amount=data.fine_amount,
        )
        db.add(line)

    db.commit()
    db.refresh(incident)
    return incident

