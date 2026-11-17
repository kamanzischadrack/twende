from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_Db
from app.schemas.rate_plan import (
    RatePlanCreate,
    RatePlanUpdate,
    RatePlanResponse
)
from app.schemas.pricing import (
    PricingQuoteRequest,
    PricingQuoteResponse
)
from app.services import pricing_service

router = APIRouter(
    prefix="/tenants/{tenant_id}",
    tags=["Rate Plans & Pricing Engine"]
)


@router.post("/rate-plans", response_model=RatePlanResponse, status_code=status.HTTP_201_CREATED)
def create_rate_plan(tenant_id: UUID, data: RatePlanCreate, db: Session = Depends(get_Db)):
    return pricing_service.create_rate_plan(db, tenant_id, data)


@router.get("/rate-plans", response_model=list[RatePlanResponse])
def list_rate_plans(
    tenant_id: UUID,
    category_id: UUID | None = None,
    vehicle_id: UUID | None = None,
    active_only: bool = True,
    db: Session = Depends(get_Db)
):
    return pricing_service.list_rate_plans(db, tenant_id, category_id, vehicle_id, active_only)


@router.get("/rate-plans/{plan_id}", response_model=RatePlanResponse)
def get_rate_plan(tenant_id: UUID, plan_id: UUID, db: Session = Depends(get_Db)):
    plan = pricing_service.get_rate_plan(db, tenant_id, plan_id)
    if not plan:
        raise HTTPException(status_code=404, detail="Rate plan not found.")
    return plan


@router.put("/rate-plans/{plan_id}", response_model=RatePlanResponse)
def update_rate_plan(tenant_id: UUID, plan_id: UUID, data: RatePlanUpdate, db: Session = Depends(get_Db)):
    updated = pricing_service.update_rate_plan(db, tenant_id, plan_id, data)
    if not updated:
        raise HTTPException(status_code=404, detail="Rate plan not found.")
    return updated


@router.post("/pricing/calculate-quote", response_model=PricingQuoteResponse)
def calculate_quote(tenant_id: UUID, quote_request: PricingQuoteRequest, db: Session = Depends(get_Db)):
    try:
        return pricing_service.calculate_quote(db, tenant_id, quote_request)
    except ValueError as err:
        raise HTTPException(status_code=400, detail=str(err))
