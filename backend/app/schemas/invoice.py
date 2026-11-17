import uuid
from datetime import date, datetime
from pydantic import BaseModel, ConfigDict
from app.core.enums import InvoiceType, InvoiceStatus


class InvoiceLineCreate(BaseModel):
    line_type: str
    description: str
    quantity: float = 1.0
    unit_price: float
    tax_rate: float = 0.18


class InvoiceCreate(BaseModel):
    customer_id: uuid.UUID
    contract_id: uuid.UUID | None = None
    invoice_type: InvoiceType = InvoiceType.INVOICE
    issue_date: date = date.today()
    due_date: date | None = None
    lines: list[InvoiceLineCreate]
    notes: str | None = None


class InvoiceLineResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    line_type: str
    description: str
    quantity: float
    unit_price: float
    tax_rate: float
    tax_amount: float
    line_total: float


class InvoiceResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    invoice_number: str
    tenant_id: uuid.UUID
    customer_id: uuid.UUID
    contract_id: uuid.UUID | None
    invoice_type: InvoiceType
    issue_date: date
    due_date: date | None
    subtotal: float
    tax_total: float
    discount_total: float
    grand_total: float
    paid_amount: float
    balance_due: float
    ebm_reference: str | None
    ebm_signature: str | None
    ebm_status: str | None
    status: InvoiceStatus
    notes: str | None
    lines: list[InvoiceLineResponse] = []
    created_at: datetime


class AgingBracket(BaseModel):
    current: float
    days_30: float
    days_60: float
    days_90_plus: float
    total_outstanding: float


class CustomerStatementResponse(BaseModel):
    customer_id: uuid.UUID
    customer_name: str
    credit_limit: float
    outstanding_balance: float
    aging: AgingBracket
    invoices: list[InvoiceResponse]

