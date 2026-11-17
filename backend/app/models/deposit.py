import uuid
from sqlalchemy import String, Numeric, Text, ForeignKey, Enum as SQLAlchemyEnum
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import TenantModel
from app.core.enums import DepositStatus, PaymentMethod


class Deposit(TenantModel):
    __tablename__ = "deposits"

    deposit_number: Mapped[str] = mapped_column(
        String(50),
        unique=True,
        index=True,
        nullable=False
    )

    contract_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("contracts.id"),
        nullable=False,
        index=True
    )

    customer_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("customers.id"),
        nullable=False,
        index=True
    )

    amount: Mapped[float] = mapped_column(
        Numeric(12, 2),
        nullable=False
    )

    held_amount: Mapped[float] = mapped_column(
        Numeric(12, 2),
        default=0.0,
        nullable=False
    )

    applied_amount: Mapped[float] = mapped_column(
        Numeric(12, 2),
        default=0.0,
        nullable=False
    )

    refunded_amount: Mapped[float] = mapped_column(
        Numeric(12, 2),
        default=0.0,
        nullable=False
    )

    status: Mapped[DepositStatus] = mapped_column(
        SQLAlchemyEnum(DepositStatus, native_enum=False),
        default=DepositStatus.HELD,
        nullable=False,
        index=True
    )

    payment_method: Mapped[PaymentMethod | None] = mapped_column(
        SQLAlchemyEnum(PaymentMethod, native_enum=False),
        nullable=True
    )

    refund_reference: Mapped[str | None] = mapped_column(
        String(100),
        nullable=True
    )

    notes: Mapped[str | None] = mapped_column(
        Text,
        nullable=True
    )

    contract: Mapped["Contract"] = relationship()
    customer: Mapped["Customer"] = relationship()

