import uuid
from datetime import datetime
from pydantic import BaseModel, ConfigDict
from app.core.enums import PaymentMethod, PaymentStatus, DepositStatus


class PaymentInitiateRequest(BaseModel):
    customer_id: uuid.UUID
    invoice_id: uuid.UUID | None = None
    deposit_id: uuid.UUID | None = None
    amount: float
    currency: str = "RWF"
    payment_method: PaymentMethod = PaymentMethod.MTN_MOMO
    phone_number: str
    customer_email: str
    customer_name: str
    redirect_url: str = "https://twende.rw/payment-callback"


class PaymentInitiateResponse(BaseModel):
    payment_id: uuid.UUID
    payment_number: str
    tx_ref: str
    amount: float
    currency: str
    status: PaymentStatus
    checkout_url: str | None = None
    provider_message: str | None = None


class PaymentAllocationRequest(BaseModel):
    invoice_id: uuid.UUID
    amount: float


class PaymentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    payment_number: str
    tenant_id: uuid.UUID
    customer_id: uuid.UUID
    payment_method: PaymentMethod
    amount: float
    currency: str
    reference: str | None
    provider_status: str | None
    status: PaymentStatus
    paid_at: datetime | None
    created_at: datetime


class DepositCreateRequest(BaseModel):
    contract_id: uuid.UUID
    customer_id: uuid.UUID
    amount: float
    payment_method: PaymentMethod = PaymentMethod.MTN_MOMO
    notes: str | None = None


class DepositRefundRequest(BaseModel):
    amount: float
    reason: str
    refund_reference: str | None = None


class DepositResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    deposit_number: str
    tenant_id: uuid.UUID
    contract_id: uuid.UUID
    customer_id: uuid.UUID
    amount: float
    held_amount: float
    applied_amount: float
    refunded_amount: float
    status: DepositStatus
    payment_method: PaymentMethod | None
    notes: str | None
    created_at: datetime

