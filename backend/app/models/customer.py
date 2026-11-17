from datetime import date
from sqlalchemy import (
    String,
    Numeric,
    Date,
    Boolean,
    JSON,
    Enum as SQLAlchemyEnum,
    UniqueConstraint
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import TenantModel
from app.core.enums import CustomerType, RiskStatus


class Customer(TenantModel):
    __tablename__ = "customers"

    __table_args__ = (
        UniqueConstraint("tenant_id", "phone", name="uq_customer_tenant_phone"),
    )

    customer_type: Mapped[CustomerType] = mapped_column(
        SQLAlchemyEnum(CustomerType, native_enum=False),
        default=CustomerType.INDIVIDUAL,
        nullable=False
    )

    name: Mapped[str] = mapped_column(
        String(150),
        nullable=False
    )

    trade_name: Mapped[str | None] = mapped_column(
        String(150),
        nullable=True
    )

    tin_number: Mapped[str | None] = mapped_column(
        String(50),
        nullable=True
    )

    phone: Mapped[str] = mapped_column(
        String(30),
        nullable=False,
        index=True
    )

    email: Mapped[str | None] = mapped_column(
        String(150),
        nullable=True
    )

    national_id_or_passport: Mapped[str | None] = mapped_column(
        String(50),
        nullable=True
    )

    driving_licence_number: Mapped[str | None] = mapped_column(
        String(50),
        nullable=True
    )

    licence_expiry_date: Mapped[date | None] = mapped_column(
        Date,
        nullable=True
    )

    licence_classes: Mapped[list[str]] = mapped_column(
        JSON,
        default=list,
        nullable=False
    )

    risk_status: Mapped[RiskStatus] = mapped_column(
        SQLAlchemyEnum(RiskStatus, native_enum=False),
        default=RiskStatus.CLEAR,
        nullable=False,
        index=True
    )

    risk_notes: Mapped[str | None] = mapped_column(
        String(500),
        nullable=True
    )

    credit_limit: Mapped[float] = mapped_column(
        Numeric(14, 2),
        default=0.0,
        nullable=False
    )

    outstanding_balance: Mapped[float] = mapped_column(
        Numeric(14, 2),
        default=0.0,
        nullable=False
    )

    is_tax_exempt: Mapped[bool] = mapped_column(
        Boolean,
        default=False,
        nullable=False
    )

    drivers: Mapped[list["CustomerDriver"]] = relationship(
        back_populates="customer",
        cascade="all, delete-orphan"
    )

