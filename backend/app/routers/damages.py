import uuid
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from sqlalchemy import select

from app.core.database import get_db
from app.dependencies.auth import get_current_user
from app.models.user import User
from app.models.damage import DamageRecord
from app.models.incident import Incident
from app.schemas.damage_incident import (
    DamageRecordCreate,
    DamageRecordResponse,
    IncidentCreate,
    IncidentResponse,
)
from app.services.damage_service import (
    create_damage_record,
    record_incident,
)

router = APIRouter(tags=["damages_and_incidents"])


@router.post("/damages", response_model=DamageRecordResponse, status_code=status.HTTP_201_CREATED)
def make_damage_record(
    req: DamageRecordCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return create_damage_record(
        db=db,
        tenant_id=current_user.tenant_id,
        data=req,
        user_id=current_user.id,
    )


@router.get("/damages", response_model=list[DamageRecordResponse])
def list_damages(
    vehicle_id: uuid.UUID | None = None,
    contract_id: uuid.UUID | None = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    query = select(DamageRecord).where(DamageRecord.tenant_id == current_user.tenant_id)
    if vehicle_id:
        query = query.where(DamageRecord.vehicle_id == vehicle_id)
    if contract_id:
        query = query.where(DamageRecord.contract_id == contract_id)
    query = query.order_by(DamageRecord.discovery_date.desc())
    return list(db.execute(query).scalars().all())


@router.post("/incidents", response_model=IncidentResponse, status_code=status.HTTP_201_CREATED)
def log_incident(
    req: IncidentCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return record_incident(
        db=db,
        tenant_id=current_user.tenant_id,
        data=req,
        user_id=current_user.id,
    )


@router.get("/incidents", response_model=list[IncidentResponse])
def list_incidents(
    vehicle_id: uuid.UUID | None = None,
    contract_id: uuid.UUID | None = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    query = select(Incident).where(Incident.tenant_id == current_user.tenant_id)
    if vehicle_id:
        query = query.where(Incident.vehicle_id == vehicle_id)
    if contract_id:
        query = query.where(Incident.contract_id == contract_id)
    query = query.order_by(Incident.incident_date.desc())
    return list(db.execute(query).scalars().all())

