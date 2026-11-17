import uuid
from datetime import datetime
from sqlalchemy import String, Numeric, DateTime, JSON, ForeignKey, Enum as SQLAlchemyEnum
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import TenantModel
from app.core.enums import PaymentMethod, PaymentStatus


class Payment(TenantModel):
    __tablename__ = "payments"

    payment_number: Mapped[str] = mapped_column(
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

    payment_method: Mapped[PaymentMethod] = mapped_column(
        SQLAlchemyEnum(PaymentMethod, native_enum=False),
        nullable=False
    )

    amount: Mapped[float] = mapped_column(
        Numeric(12, 2),
        nullable=False
    )

    currency: Mapped[str] = mapped_column(
        String(3),
        default="RWF",
        nullable=False
    )

    reference: Mapped[str | None] = mapped_column(
        String(100),
        nullable=True,
        index=True
    )

    provider_status: Mapped[str | None] = mapped_column(
        String(50),
        nullable=True
    )

    provider_reference: Mapped[str | None] = mapped_column(
        String(100),
        nullable=True
    )

    status: Mapped[PaymentStatus] = mapped_column(
        SQLAlchemyEnum(PaymentStatus, native_enum=False),
        default=PaymentStatus.PENDING,
        nullable=False,
        index=True
    )

    paid_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True
    )

    metadata_json: Mapped[dict | None] = mapped_column(
        JSON,
        nullable=True
    )

    customer: Mapped["Customer"] = relationship()
    allocations: Mapped[list["PaymentAllocation"]] = relationship(back_populates="payment", cascade="all, delete-orphan")


class PaymentAllocation(TenantModel):
    __tablename__ = "payment_allocations"

    payment_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("payments.id"),
        nullable=False,
        index=True
    )

    invoice_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("invoices.id"),
        nullable=False,
        index=True
    )

    allocated_amount: Mapped[float] = mapped_column(
        Numeric(12, 2),
        nullable=False
    )

    payment: Mapped["Payment"] = relationship(back_populates="allocations")
    invoice: Mapped["Invoice"] = relationship(back_populates="allocations")

