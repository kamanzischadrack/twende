import uuid
from sqlalchemy import (
    String,
    Integer,
    Numeric,
    Boolean,
    ForeignKey,
    Enum as SQLAlchemyEnum
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import TenantModel
from app.core.enums import FuelPolicy


class RatePlan(TenantModel):
    __tablename__ = "rate_plans"

    name: Mapped[str] = mapped_column(
        String(100),
        nullable=False
    )

    category_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("vehicle_categories.id"),
        nullable=False,
        index=True
    )

    vehicle_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("vehicles.id"),
        nullable=True,
        index=True
    )

    currency: Mapped[str] = mapped_column(
        String(3),
        default="RWF",
        nullable=False
    )

    hourly_rate: Mapped[float | None] = mapped_column(
        Numeric(12, 2),
        nullable=True
    )

    daily_rate: Mapped[float] = mapped_column(
        Numeric(12, 2),
        nullable=False
    )

    weekly_rate: Mapped[float] = mapped_column(
        Numeric(12, 2),
        nullable=False
    )

    monthly_rate: Mapped[float] = mapped_column(
        Numeric(12, 2),
        nullable=False
    )

    included_km_per_day: Mapped[int] = mapped_column(
        Integer,
        default=200,
        nullable=False
    )

    excess_km_rate: Mapped[float] = mapped_column(
        Numeric(10, 2),
        default=150.0,
        nullable=False
    )

    fuel_policy: Mapped[FuelPolicy] = mapped_column(
        SQLAlchemyEnum(FuelPolicy, native_enum=False),
        default=FuelPolicy.FULL_TO_FULL,
        nullable=False
    )

    refuel_surcharge_fee: Mapped[float] = mapped_column(
        Numeric(10, 2),
        default=5000.0,
        nullable=False
    )

    grace_period_minutes: Mapped[int] = mapped_column(
        Integer,
        default=60,
        nullable=False
    )

    default_deposit_amount: Mapped[float] = mapped_column(
        Numeric(12, 2),
        default=100000.0,
        nullable=False
    )

    is_active: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
        nullable=False
    )

    category: Mapped["VehicleCategory"] = relationship(
        back_populates="rate_plans"
    )

    vehicle: Mapped["Vehicle | None"] = relationship()

