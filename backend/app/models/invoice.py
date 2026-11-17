import uuid
from datetime import date
from sqlalchemy import String, Date, Numeric, Text, ForeignKey, Enum as SQLAlchemyEnum
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import TenantModel
from app.core.enums import InvoiceType, InvoiceStatus


class Invoice(TenantModel):
    __tablename__ = "invoices"

    invoice_number: Mapped[str] = mapped_column(
        String(50),
        unique=True,
        index=True,
        nullable=False
    )

    customer_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("customers.id"),
        nullable=False,
        index=True
    )

    contract_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("contracts.id"),
        nullable=True,
        index=True
    )

    invoice_type: Mapped[InvoiceType] = mapped_column(
        SQLAlchemyEnum(InvoiceType, native_enum=False),
        default=InvoiceType.INVOICE,
        nullable=False
    )

    issue_date: Mapped[date] = mapped_column(
        Date,
        nullable=False
    )

    due_date: Mapped[date | None] = mapped_column(
        Date,
        nullable=True
    )

    subtotal: Mapped[float] = mapped_column(
        Numeric(12, 2),
        default=0.0,
        nullable=False
    )

    tax_total: Mapped[float] = mapped_column(
        Numeric(12, 2),
        default=0.0,
        nullable=False
    )

    discount_total: Mapped[float] = mapped_column(
        Numeric(12, 2),
        default=0.0,
        nullable=False
    )

    grand_total: Mapped[float] = mapped_column(
        Numeric(12, 2),
        default=0.0,
        nullable=False
    )

    paid_amount: Mapped[float] = mapped_column(
        Numeric(12, 2),
        default=0.0,
        nullable=False
    )

    balance_due: Mapped[float] = mapped_column(
        Numeric(12, 2),
        default=0.0,
        nullable=False
    )

    ebm_reference: Mapped[str | None] = mapped_column(
        String(100),
        nullable=True
    )

    ebm_signature: Mapped[str | None] = mapped_column(
        String(500),
        nullable=True
    )

    ebm_status: Mapped[str | None] = mapped_column(
        String(50),
        nullable=True
    )

    status: Mapped[InvoiceStatus] = mapped_column(
        SQLAlchemyEnum(InvoiceStatus, native_enum=False),
        default=InvoiceStatus.DRAFT,
        nullable=False,
        index=True
    )

    notes: Mapped[str | None] = mapped_column(
        Text,
        nullable=True
    )

    customer: Mapped["Customer"] = relationship()
    contract: Mapped["Contract | None"] = relationship()
    lines: Mapped[list["InvoiceLine"]] = relationship(back_populates="invoice", cascade="all, delete-orphan")
    allocations: Mapped[list["PaymentAllocation"]] = relationship(back_populates="invoice")


class InvoiceLine(TenantModel):
    __tablename__ = "invoice_lines"

    invoice_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("invoices.id"),
        nullable=False,
        index=True
    )

    line_type: Mapped[str] = mapped_column(
        String(50),
        nullable=False
    )

    description: Mapped[str] = mapped_column(
        String(255),
        nullable=False
    )

    quantity: Mapped[float] = mapped_column(
        Numeric(10, 2),
        default=1.0,
        nullable=False
    )

    unit_price: Mapped[float] = mapped_column(
        Numeric(12, 2),
        nullable=False
    )

    tax_rate: Mapped[float] = mapped_column(
        Numeric(5, 4),
        default=0.18,
        nullable=False
    )

    tax_amount: Mapped[float] = mapped_column(
        Numeric(12, 2),
        default=0.0,
        nullable=False
    )

    line_total: Mapped[float] = mapped_column(
        Numeric(12, 2),
        nullable=False
    )

    invoice: Mapped["Invoice"] = relationship(back_populates="lines")

