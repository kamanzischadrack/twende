from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_Db
from app.core.enums import RiskStatus
from app.schemas.customer import (
    CustomerCreate,
    CustomerUpdate,
    CustomerRiskUpdate,
    CustomerResponse
)
from app.schemas.customer_driver import (
    CustomerDriverCreate,
    CustomerDriverResponse
)
from app.services import customer_service

router = APIRouter(
    prefix="/tenants/{tenant_id}/customers",
    tags=["Customers & Risk Management"]
)


@router.post("", response_model=CustomerResponse, status_code=status.HTTP_201_CREATED)
def create_customer(tenant_id: UUID, data: CustomerCreate, db: Session = Depends(get_Db)):
    try:
        return customer_service.create_customer(db, tenant_id, data)
    except ValueError as err:
        raise HTTPException(status_code=400, detail=str(err))


@router.get("", response_model=list[CustomerResponse])
def list_customers(
    tenant_id: UUID,
    risk_status: RiskStatus | None = None,
    search: str | None = None,
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_Db)
):
    return customer_service.list_customers(db, tenant_id, risk_status, search, skip, limit)


@router.get("/{customer_id}", response_model=CustomerResponse)
def get_customer(tenant_id: UUID, customer_id: UUID, db: Session = Depends(get_Db)):
    customer = customer_service.get_customer(db, tenant_id, customer_id)
    if not customer:
        raise HTTPException(status_code=404, detail="Customer not found.")
    return customer


@router.put("/{customer_id}", response_model=CustomerResponse)
def update_customer(tenant_id: UUID, customer_id: UUID, data: CustomerUpdate, db: Session = Depends(get_Db)):
    try:
        updated = customer_service.update_customer(db, tenant_id, customer_id, data)
        if not updated:
            raise HTTPException(status_code=404, detail="Customer not found.")
        return updated
    except ValueError as err:
        raise HTTPException(status_code=400, detail=str(err))


@router.patch("/{customer_id}/risk-status", response_model=CustomerResponse)
def update_risk_status(tenant_id: UUID, customer_id: UUID, risk_update: CustomerRiskUpdate, db: Session = Depends(get_Db)):
    try:
        return customer_service.update_customer_risk_status(db, tenant_id, customer_id, risk_update)
    except ValueError as err:
        raise HTTPException(status_code=400, detail=str(err))


@router.post("/{customer_id}/drivers", response_model=CustomerDriverResponse, status_code=status.HTTP_201_CREATED)
def add_customer_driver(tenant_id: UUID, customer_id: UUID, data: CustomerDriverCreate, db: Session = Depends(get_Db)):
    if data.customer_id != customer_id:
        raise HTTPException(status_code=400, detail="Mismatched customer ID in path and body.")
    try:
        return customer_service.create_customer_driver(db, tenant_id, data)
    except ValueError as err:
        raise HTTPException(status_code=400, detail=str(err))


@router.get("/{customer_id}/drivers", response_model=list[CustomerDriverResponse])
def list_customer_drivers(tenant_id: UUID, customer_id: UUID, db: Session = Depends(get_Db)):
    return customer_service.list_customer_drivers(db, tenant_id, customer_id)
