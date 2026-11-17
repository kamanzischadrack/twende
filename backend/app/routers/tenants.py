from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status, Response
from sqlalchemy.orm import Session

from app.core.database import get_Db

from app.schemas.tenant import (
    TenantCreate,
    TenantUpdate,
    TenantResponse
)

from app.services import tenant_service

router = APIRouter(
    prefix="/tenants",
    tags=["Tenants"]
)


@router.post(
    "",
    response_model=TenantResponse,
    status_code=status.HTTP_201_CREATED)
def create_tenant(
        tenant_data: TenantCreate,
        db: Session = Depends(get_Db)
):
    return tenant_service.create_tenant(db, tenant_data)


@router.get("", response_model=list[TenantResponse])
def get_tenants(skip: int = 0, limit: int = 100, db: Session = Depends(get_Db)):
    return tenant_service.get_tenants(db, skip, limit)


@router.get("/{tenant_id}", response_model=TenantResponse)
def get_tenant(tenant_id: UUID, db: Session = Depends(get_Db)):
    tenant = tenant_service.get_tenant(db, tenant_id)
    if tenant is None:
        raise HTTPException(status_code=404, detail=f"Tenant with id {tenant_id} is not found ")
    return tenant


@router.patch("/{tenant_id}",response_model=TenantResponse)
def update_tenant(tenant_id: UUID, tenant_data: TenantUpdate, db:Session=Depends(get_Db)):
    tenant = tenant_service.update_tenant(db,tenant_id, tenant_data)

    if tenant is None:
        raise HTTPException(status_code=404, detail="Tenant not found")
    return tenant


@router.delete("/{tenant_id}",status_code=status.HTTP_204_NO_CONTENT)
def delete_tenant(tenant_id:UUID, db: Session = Depends(get_Db)):
    try:
        deleted = tenant_service.delete_tenant(db,tenant_id)
    except ValueError as error:
        raise HTTPException(status_code=409,detail=str(error))
    if not deleted:
        raise HTTPException(
            status_code=404,
            detail="Tenant id not found"
        )
    return Response(status_code=204)