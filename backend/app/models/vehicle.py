import uuid
from sqlalchemy import (
    String,
    Integer,
    Numeric,
    ForeignKey,
    Enum as SQLAlchemyEnum,
    UniqueConstraint
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import TenantModel
from app.core.enums import VehicleStatus, OwnershipType


class Vehicle(TenantModel):
    __tablename__ = "vehicles"

    __table_args__ = (
        UniqueConstraint("tenant_id", "plate_number", name="uq_vehicle_tenant_plate"),
    )

    branch_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("branches.id"),
        nullable=False,
        index=True
    )

    category_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("vehicle_categories.id"),
        nullable=False,
        index=True
    )

    plate_number: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
        index=True
    )

    vin: Mapped[str | None] = mapped_column(
        String(50),
        nullable=True
    )

    make: Mapped[str] = mapped_column(
        String(50),
        nullable=False
    )

    model: Mapped[str] = mapped_column(
        String(50),
        nullable=False
    )

    year: Mapped[int] = mapped_column(
        Integer,
        nullable=False
    )

    color: Mapped[str | None] = mapped_column(
        String(50),
        nullable=True
    )

    status: Mapped[VehicleStatus] = mapped_column(
        SQLAlchemyEnum(VehicleStatus, native_enum=False),
        default=VehicleStatus.AVAILABLE,
        nullable=False,
        index=True
    )

    current_mileage: Mapped[int] = mapped_column(
        Integer,
        default=0,
        nullable=False
    )

    fuel_tank_capacity_l: Mapped[float] = mapped_column(
        Numeric(8, 2),
        default=60.0,
        nullable=False
    )

    current_fuel_level_pct: Mapped[float] = mapped_column(
        Numeric(5, 2),
        default=100.0,
        nullable=False
    )

    ownership_type: Mapped[OwnershipType] = mapped_column(
        SQLAlchemyEnum(OwnershipType, native_enum=False),
        default=OwnershipType.OWNED,
        nullable=False
    )

    purchase_cost: Mapped[float | None] = mapped_column(
        Numeric(14, 2),
        nullable=True
    )

    annual_depreciation_rate: Mapped[float | None] = mapped_column(
        Numeric(5, 2),
        nullable=True
    )

    status_reason: Mapped[str | None] = mapped_column(
        String(255),
        nullable=True
    )

    branch: Mapped["Branch"] = relationship()

    category: Mapped["VehicleCategory"] = relationship(
        back_populates="vehicles"
    )

    documents: Mapped[list["VehicleDocument"]] = relationship(
        back_populates="vehicle",
        cascade="all, delete-orphan"
    )

