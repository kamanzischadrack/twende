import uuid
from datetime import datetime, timezone, date
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import select

from app.core.database import get_db
from app.dependencies.auth import get_current_user
from app.models.user import User
from app.models.invoice import Invoice, InvoiceLine
from app.core.enums import InvoiceStatus
from app.schemas.invoice import (
    InvoiceCreate,
    InvoiceResponse,
    CustomerStatementResponse,
)
from app.services.payment_service import payment_service

router = APIRouter(prefix="/invoices", tags=["invoices"])


@router.post("", response_model=InvoiceResponse, status_code=status.HTTP_201_CREATED)
def create_invoice(
    req: InvoiceCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    subtotal = sum(l.quantity * l.unit_price for l in req.lines)
    tax_total = sum((l.quantity * l.unit_price) * l.tax_rate for l in req.lines)
    grand_total = subtotal + tax_total

    inv_num = f"INV-{datetime.now(timezone.utc).strftime('%Y%m%d')}-{uuid.uuid4().hex[:6].upper()}"

    invoice = Invoice(
        tenant_id=current_user.tenant_id,
        invoice_number=inv_num,
        customer_id=req.customer_id,
        contract_id=req.contract_id,
        invoice_type=req.invoice_type,
        issue_date=req.issue_date,
        due_date=req.due_date,
        subtotal=round(subtotal, 2),
        tax_total=round(tax_total, 2),
        grand_total=round(grand_total, 2),
        paid_amount=0.0,
        balance_due=round(grand_total, 2),
        status=InvoiceStatus.ISSUED,
        notes=req.notes,
        created_by=current_user.id,
    )
    db.add(invoice)
    db.flush()

    for l in req.lines:
        line_tot = (l.quantity * l.unit_price) * (1.0 + l.tax_rate)
        inv_line = InvoiceLine(
            tenant_id=current_user.tenant_id,
            invoice_id=invoice.id,
            line_type=l.line_type,
            description=l.description,
            quantity=l.quantity,
            unit_price=l.unit_price,
            tax_rate=l.tax_rate,
            tax_amount=round((l.quantity * l.unit_price) * l.tax_rate, 2),
            line_total=round(line_tot, 2),
        )
        db.add(inv_line)

    db.commit()
    db.refresh(invoice)
    return invoice


@router.get("", response_model=list[InvoiceResponse])
def list_invoices(
    customer_id: uuid.UUID | None = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    query = select(Invoice).where(Invoice.tenant_id == current_user.tenant_id)
    if customer_id:
        query = query.where(Invoice.customer_id == customer_id)
    query = query.order_by(Invoice.issue_date.desc())
    return list(db.execute(query).scalars().all())


@router.get("/{invoice_id}", response_model=InvoiceResponse)
def get_invoice(
    invoice_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    invoice = db.execute(
        select(Invoice).where(
            Invoice.id == invoice_id,
            Invoice.tenant_id == current_user.tenant_id,
        )
    ).scalar_one_or_none()

    if not invoice:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Invoice not found")

    return invoice


@router.get("/customer/{customer_id}/statement", response_model=CustomerStatementResponse)
def get_statement(
    customer_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return payment_service.get_customer_statement(
        db=db,
        tenant_id=current_user.tenant_id,
        customer_id=customer_id,
    )

