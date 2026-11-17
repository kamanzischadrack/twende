from datetime import date
from sqlalchemy import String, Numeric, Boolean, Date
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import TenantModel


class TaxRate(TenantModel):
    __tablename__ = "tax_rates"

    name: Mapped[str] = mapped_column(
        String(50),
        nullable=False
    )

    rate: Mapped[float] = mapped_column(
        Numeric(5, 4),
        nullable=False
    )

    category: Mapped[str] = mapped_column(
        String(50),
        default="STANDARD",
        nullable=False
    )

    is_inclusive: Mapped[bool] = mapped_column(
        Boolean,
        default=False,
        nullable=False
    )

    is_default: Mapped[bool] = mapped_column(
        Boolean,
        default=False,
        nullable=False
    )

    is_active: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
        nullable=False
    )


class Discount(TenantModel):
    __tablename__ = "discounts"

    code: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        index=True
    )

    discount_type: Mapped[str] = mapped_column(
        String(20),
        nullable=False
    )

    value: Mapped[float] = mapped_column(
        Numeric(12, 2),
        nullable=False
    )

    max_discount_amount: Mapped[float | None] = mapped_column(
        Numeric(12, 2),
        nullable=True
    )

    valid_from: Mapped[date | None] = mapped_column(
        Date,
        nullable=True
    )

    valid_until: Mapped[date | None] = mapped_column(
        Date,
        nullable=True
    )

    is_active: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
        nullable=False
    )

