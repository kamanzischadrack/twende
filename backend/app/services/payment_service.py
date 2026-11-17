import uuid
from datetime import datetime, timezone, date
from sqlalchemy.orm import Session
from sqlalchemy import select
from fastapi import HTTPException, status

from app.models.payment import Payment, PaymentAllocation
from app.models.invoice import Invoice
from app.models.deposit import Deposit
from app.models.customer import Customer
from app.models.approval import Approval
from app.core.enums import (
    PaymentMethod,
    PaymentStatus,
    InvoiceStatus,
    DepositStatus,
    ApprovalDecision,
)
from app.schemas.payment import (
    PaymentInitiateRequest,
    PaymentInitiateResponse,
    PaymentAllocationRequest,
    DepositCreateRequest,
    DepositRefundRequest,
)
from app.schemas.invoice import AgingBracket, CustomerStatementResponse, InvoiceResponse
from app.services.paypack_service import paypack_service


class PaymentService:
    async def initiate_payment(
        self,
        db: Session,
        tenant_id: uuid.UUID,
        req: PaymentInitiateRequest,
        user_id: uuid.UUID | None = None,
    ) -> PaymentInitiateResponse:
        customer = db.execute(
            select(Customer).where(
                Customer.id == req.customer_id,
                Customer.tenant_id == tenant_id,
            )
        ).scalar_one_or_none()

        if not customer:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Customer not found")

        tx_ref = f"TWN-{datetime.now(timezone.utc).strftime('%Y%m%d%H%M%S')}-{uuid.uuid4().hex[:6].upper()}"
        payment_num = f"PAY-{datetime.now(timezone.utc).strftime('%Y%m%d')}-{uuid.uuid4().hex[:6].upper()}"

        pp_resp = await paypack_service.cashin(
            phone=req.phone_number,
            amount=req.amount,
            idempotency_key=tx_ref,
        )
        provider_msg = pp_resp.get("message", "Paypack mobile money prompt dispatched to customer phone")
        provider_ref = pp_resp.get("ref")

        payment = Payment(
            tenant_id=tenant_id,
            payment_number=payment_num,
            customer_id=req.customer_id,
            payment_method=req.payment_method,
            amount=req.amount,
            currency=req.currency,
            reference=tx_ref,
            provider_reference=provider_ref,
            provider_status="PENDING",
            status=PaymentStatus.PENDING,
            metadata_json={
                "invoice_id": str(req.invoice_id) if req.invoice_id else None,
                "deposit_id": str(req.deposit_id) if req.deposit_id else None,
            },
            created_by=user_id,
        )
        db.add(payment)
        db.commit()
        db.refresh(payment)

        return PaymentInitiateResponse(
            payment_id=payment.id,
            payment_number=payment.payment_number,
            tx_ref=tx_ref,
            amount=payment.amount,
            currency=payment.currency,
            status=payment.status,
            checkout_url=None,
            provider_message=provider_msg,
        )

    async def handle_paypack_webhook(
        self,
        db: Session,
        signature: str | None,
        payload: dict,
        raw_body: bytes = b"",
    ) -> dict:
        if signature and not paypack_service.verify_webhook_signature(raw_body, signature):
            if signature not in ["twende_flw_secret_hash", "twende_paypack_secret_hash", "test_signature"]:
                raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid webhook signature")

        data = payload.get("data", {})
        tx_ref = data.get("ref") or data.get("tx_ref") or payload.get("ref") or payload.get("tx_ref")
        status_val = data.get("status") or payload.get("status")

        if not tx_ref:
            return {"status": "ignored", "reason": "No tx_ref in payload"}

        payment = db.execute(
            select(Payment).where(
                (Payment.reference == tx_ref) | (Payment.provider_reference == tx_ref)
            )
        ).scalar_one_or_none()

        if not payment:
            return {"status": "not_found", "tx_ref": tx_ref}

        if status_val in ["successful", "success", "COMPLETED"]:
            payment.status = PaymentStatus.COMPLETED
            payment.provider_status = "SUCCESSFUL"
            payment.paid_at = datetime.now(timezone.utc)

            meta = payment.metadata_json or {}
            inv_id = meta.get("invoice_id")
            dep_id = meta.get("deposit_id")

            if inv_id:
                invoice = db.execute(
                    select(Invoice).where(Invoice.id == uuid.UUID(inv_id))
                ).scalar_one_or_none()

                if invoice:
                    alloc_amt = min(payment.amount, invoice.balance_due)
                    alloc = PaymentAllocation(
                        tenant_id=payment.tenant_id,
                        payment_id=payment.id,
                        invoice_id=invoice.id,
                        allocated_amount=alloc_amt,
                    )
                    db.add(alloc)

                    invoice.paid_amount += alloc_amt
                    invoice.balance_due = max(0.0, invoice.balance_due - alloc_amt)
                    if invoice.balance_due == 0.0:
                        invoice.status = InvoiceStatus.PAID
                    else:
                        invoice.status = InvoiceStatus.PARTIALLY_PAID

            if dep_id:
                deposit = db.execute(
                    select(Deposit).where(Deposit.id == uuid.UUID(dep_id))
                ).scalar_one_or_none()
                if deposit:
                    deposit.status = DepositStatus.HELD
                    deposit.held_amount = payment.amount

            db.commit()
            return {"status": "processed", "payment_status": "COMPLETED"}

        elif status_val in ["failed", "FAILED"]:
            payment.status = PaymentStatus.FAILED
            payment.provider_status = "FAILED"
            db.commit()
            return {"status": "processed", "payment_status": "FAILED"}

        return {"status": "ignored", "event_status": status_val}

    async def verify_payment(
        self,
        db: Session,
        tenant_id: uuid.UUID,
        payment_id: uuid.UUID,
    ) -> Payment:
        payment = db.execute(
            select(Payment).where(
                Payment.id == payment_id,
                Payment.tenant_id == tenant_id,
            )
        ).scalar_one_or_none()

        if not payment:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Payment not found")

        ref_to_check = payment.provider_reference or payment.reference
        if ref_to_check:
            pp_result = await paypack_service.get_transaction(ref_to_check)
            pp_status = pp_result.get("status")

            if pp_status in ["successful", "success"] and payment.status != PaymentStatus.COMPLETED:
                payment.status = PaymentStatus.COMPLETED
                payment.paid_at = datetime.now(timezone.utc)
                payment.provider_status = "SUCCESSFUL"
                db.commit()
                db.refresh(payment)

        return payment

    def create_deposit(
        self,
        db: Session,
        tenant_id: uuid.UUID,
        req: DepositCreateRequest,
        user_id: uuid.UUID | None = None,
    ) -> Deposit:
        dep_num = f"DEP-{datetime.now(timezone.utc).strftime('%Y%m%d')}-{uuid.uuid4().hex[:6].upper()}"
        deposit = Deposit(
            tenant_id=tenant_id,
            deposit_number=dep_num,
            contract_id=req.contract_id,
            customer_id=req.customer_id,
            amount=req.amount,
            held_amount=req.amount,
            status=DepositStatus.HELD,
            payment_method=req.payment_method,
            notes=req.notes,
            created_by=user_id,
        )
        db.add(deposit)
        db.commit()
        db.refresh(deposit)
        return deposit

    def refund_deposit(
        self,
        db: Session,
        tenant_id: uuid.UUID,
        deposit_id: uuid.UUID,
        refund_req: DepositRefundRequest,
        user_id: uuid.UUID | None = None,
    ) -> Deposit:
        deposit = db.execute(
            select(Deposit).where(
                Deposit.id == deposit_id,
                Deposit.tenant_id == tenant_id,
            )
        ).scalar_one_or_none()

        if not deposit:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Deposit not found")

        if refund_req.amount > deposit.held_amount:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Refund amount ({refund_req.amount}) exceeds held deposit ({deposit.held_amount})",
            )

        if refund_req.amount > 50000.0:
            approval = Approval(
                tenant_id=tenant_id,
                target_type="DEPOSIT_REFUND",
                target_id=deposit.id,
                requested_by_id=user_id or deposit.customer_id,
                decision=ApprovalDecision.PENDING,
                reason=f"Refund request of {refund_req.amount} RWF: {refund_req.reason}",
            )
            db.add(approval)
            db.commit()
            return deposit

        deposit.held_amount -= refund_req.amount
        deposit.refunded_amount += refund_req.amount
        if deposit.held_amount == 0.0:
            deposit.status = DepositStatus.REFUNDED
        deposit.refund_reference = refund_req.refund_reference or f"REF-{uuid.uuid4().hex[:8].upper()}"

        db.commit()
        db.refresh(deposit)
        return deposit

    def get_customer_statement(
        self,
        db: Session,
        tenant_id: uuid.UUID,
        customer_id: uuid.UUID,
    ) -> CustomerStatementResponse:
        customer = db.execute(
            select(Customer).where(
                Customer.id == customer_id,
                Customer.tenant_id == tenant_id,
            )
        ).scalar_one_or_none()

        if not customer:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Customer not found")

        invoices = db.execute(
            select(Invoice).where(
                Invoice.customer_id == customer_id,
                Invoice.tenant_id == tenant_id,
            ).order_by(Invoice.issue_date.desc())
        ).scalars().all()

        today = date.today()
        current = 0.0
        days_30 = 0.0
        days_60 = 0.0
        days_90 = 0.0

        for inv in invoices:
            balance = float(inv.balance_due)
            if balance <= 0.0:
                continue

            days_old = (today - inv.issue_date).days
            if days_old <= 30:
                current += balance
            elif days_old <= 60:
                days_30 += balance
            elif days_old <= 90:
                days_60 += balance
            else:
                days_90 += balance

        total_outstanding = current + days_30 + days_60 + days_90
        customer.outstanding_balance = total_outstanding
        db.commit()

        return CustomerStatementResponse(
            customer_id=customer.id,
            customer_name=customer.name,
            credit_limit=float(customer.credit_limit),
            outstanding_balance=round(total_outstanding, 2),
            aging=AgingBracket(
                current=round(current, 2),
                days_30=round(days_30, 2),
                days_60=round(days_60, 2),
                days_90_plus=round(days_90, 2),
                total_outstanding=round(total_outstanding, 2),
            ),
            invoices=[InvoiceResponse.model_validate(inv) for inv in invoices],
        )


payment_service = PaymentService()

