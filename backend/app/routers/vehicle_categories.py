from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_Db
from app.schemas.vehicle_category import (
    VehicleCategoryCreate,
    VehicleCategoryUpdate,
    VehicleCategoryResponse
)
from app.services import vehicle_service

router = APIRouter(
    prefix="/tenants/{tenant_id}/vehicle-categories",
    tags=["Vehicle Categories"]
)


@router.post("", response_model=VehicleCategoryResponse, status_code=status.HTTP_201_CREATED)
def create_category(tenant_id: UUID, data: VehicleCategoryCreate, db: Session = Depends(get_Db)):
    return vehicle_service.create_vehicle_category(db, tenant_id, data)


@router.get("", response_model=list[VehicleCategoryResponse])
def list_categories(tenant_id: UUID, skip: int = 0, limit: int = 50, db: Session = Depends(get_Db)):
    return vehicle_service.list_vehicle_categories(db, tenant_id, skip, limit)


@router.get("/{category_id}", response_model=VehicleCategoryResponse)
def get_category(tenant_id: UUID, category_id: UUID, db: Session = Depends(get_Db)):
    category = vehicle_service.get_vehicle_category(db, tenant_id, category_id)
    if not category:
        raise HTTPException(status_code=404, detail="Vehicle category not found.")
    return category


@router.put("/{category_id}", response_model=VehicleCategoryResponse)
def update_category(tenant_id: UUID, category_id: UUID, data: VehicleCategoryUpdate, db: Session = Depends(get_Db)):
    updated = vehicle_service.update_vehicle_category(db, tenant_id, category_id, data)
    if not updated:
        raise HTTPException(status_code=404, detail="Vehicle category not found.")
    return updated


@router.delete("/{category_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_category(tenant_id: UUID, category_id: UUID, db: Session = Depends(get_Db)):
    try:
        if not vehicle_service.delete_vehicle_category(db, tenant_id, category_id):
            raise HTTPException(status_code=404, detail="Vehicle category not found.")
    except ValueError as err:
        raise HTTPException(status_code=400, detail=str(err))
