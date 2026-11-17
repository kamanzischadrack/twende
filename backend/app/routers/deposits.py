import uuid
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import select

from app.core.database import get_db
from app.dependencies.auth import get_current_user
from app.models.user import User
from app.models.deposit import Deposit
from app.schemas.payment import (
    DepositCreateRequest,
    DepositRefundRequest,
    DepositResponse,
)
from app.services.payment_service import payment_service

router = APIRouter(prefix="/deposits", tags=["deposits"])


@router.post("", response_model=DepositResponse, status_code=status.HTTP_201_CREATED)
def make_deposit(
    req: DepositCreateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return payment_service.create_deposit(
        db=db,
        tenant_id=current_user.tenant_id,
        req=req,
        user_id=current_user.id,
    )


@router.get("", response_model=list[DepositResponse])
def list_deposits(
    customer_id: uuid.UUID | None = None,
    contract_id: uuid.UUID | None = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    query = select(Deposit).where(Deposit.tenant_id == current_user.tenant_id)
    if customer_id:
        query = query.where(Deposit.customer_id == customer_id)
    if contract_id:
        query = query.where(Deposit.contract_id == contract_id)
    query = query.order_by(Deposit.created_at.desc())
    return list(db.execute(query).scalars().all())


@router.post("/{deposit_id}/refund", response_model=DepositResponse)
def refund_deposit_endpoint(
    deposit_id: uuid.UUID,
    req: DepositRefundRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return payment_service.refund_deposit(
        db=db,
        tenant_id=current_user.tenant_id,
        deposit_id=deposit_id,
        refund_req=req,
        user_id=current_user.id,
    )

