from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session

from app.core.database import get_Db
from app.core.enums import VehicleStatus
from app.schemas.vehicle import (
    VehicleCreate,
    VehicleUpdate,
    VehicleStatusOverride,
    VehicleResponse
)
from app.schemas.vehicle_document import (
    VehicleDocumentCreate,
    VehicleDocumentResponse
)
from app.services import vehicle_service, document_service

router = APIRouter(
    prefix="/tenants/{tenant_id}/vehicles",
    tags=["Vehicles"]
)


@router.post("", response_model=VehicleResponse, status_code=status.HTTP_201_CREATED)
def create_vehicle(tenant_id: UUID, data: VehicleCreate, db: Session = Depends(get_Db)):
    try:
        return vehicle_service.create_vehicle(db, tenant_id, data)
    except ValueError as err:
        raise HTTPException(status_code=400, detail=str(err))


@router.get("", response_model=list[VehicleResponse])
def list_vehicles(
    tenant_id: UUID,
    branch_id: UUID | None = None,
    category_id: UUID | None = None,
    status_filter: VehicleStatus | None = Query(default=None, alias="status"),
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_Db)
):
    return vehicle_service.list_vehicles(db, tenant_id, branch_id, category_id, status_filter, skip, limit)


@router.get("/{vehicle_id}", response_model=VehicleResponse)
def get_vehicle(tenant_id: UUID, vehicle_id: UUID, db: Session = Depends(get_Db)):
    vehicle = vehicle_service.get_vehicle(db, tenant_id, vehicle_id)
    if not vehicle:
        raise HTTPException(status_code=404, detail="Vehicle not found.")
    return vehicle


@router.put("/{vehicle_id}", response_model=VehicleResponse)
def update_vehicle(tenant_id: UUID, vehicle_id: UUID, data: VehicleUpdate, db: Session = Depends(get_Db)):
    updated = vehicle_service.update_vehicle(db, tenant_id, vehicle_id, data)
    if not updated:
        raise HTTPException(status_code=404, detail="Vehicle not found.")
    return updated


@router.patch("/{vehicle_id}/override-status", response_model=VehicleResponse)
def override_vehicle_status(tenant_id: UUID, vehicle_id: UUID, override: VehicleStatusOverride, db: Session = Depends(get_Db)):
    try:
        return vehicle_service.override_vehicle_status(db, tenant_id, vehicle_id, override)
    except ValueError as err:
        raise HTTPException(status_code=400, detail=str(err))


@router.post("/{vehicle_id}/documents", response_model=VehicleDocumentResponse, status_code=status.HTTP_201_CREATED)
def add_vehicle_document(tenant_id: UUID, vehicle_id: UUID, data: VehicleDocumentCreate, db: Session = Depends(get_Db)):
    try:
        return document_service.create_vehicle_document(db, tenant_id, vehicle_id, data)
    except ValueError as err:
        raise HTTPException(status_code=400, detail=str(err))


@router.get("/{vehicle_id}/documents", response_model=list[VehicleDocumentResponse])
def list_vehicle_documents(tenant_id: UUID, vehicle_id: UUID, db: Session = Depends(get_Db)):
    return document_service.list_vehicle_documents(db, tenant_id, vehicle_id)
