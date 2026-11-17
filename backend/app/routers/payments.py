import uuid
from fastapi import APIRouter, Depends, Header, Request, status
from sqlalchemy.orm import Session
from sqlalchemy import select

from app.core.database import get_db
from app.dependencies.auth import get_current_user
from app.models.user import User
from app.models.payment import Payment
from app.schemas.payment import (
    PaymentInitiateRequest,
    PaymentInitiateResponse,
    PaymentResponse,
)
from app.services.payment_service import payment_service

router = APIRouter(prefix="/payments", tags=["payments"])


@router.post("/initiate", response_model=PaymentInitiateResponse, status_code=status.HTTP_201_CREATED)
async def initiate_payment(
    req: PaymentInitiateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return await payment_service.initiate_payment(
        db=db,
        tenant_id=current_user.tenant_id,
        req=req,
        user_id=current_user.id,
    )


@router.post("/webhook/paypack")
async def paypack_webhook_listener(
    request: Request,
    signature: str | None = Header(None, alias="x-paypack-signature"),
    verif_hash: str | None = Header(None, alias="verif-hash"),
    db: Session = Depends(get_db),
):
    raw_body = await request.body()
    payload = await request.json()
    sig = signature or verif_hash
    return await payment_service.handle_paypack_webhook(
        db=db,
        signature=sig,
        payload=payload,
        raw_body=raw_body,
    )


@router.get("/verify/{payment_id}", response_model=PaymentResponse)
async def verify_payment_status(
    payment_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return await payment_service.verify_payment(
        db=db,
        tenant_id=current_user.tenant_id,
        payment_id=payment_id,
    )


@router.get("", response_model=list[PaymentResponse])
def list_payments(
    customer_id: uuid.UUID | None = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    query = select(Payment).where(Payment.tenant_id == current_user.tenant_id)
    if customer_id:
        query = query.where(Payment.customer_id == customer_id)
    query = query.order_by(Payment.created_at.desc())
    return list(db.execute(query).scalars().all())

