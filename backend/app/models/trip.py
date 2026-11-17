import uuid
from datetime import datetime
from sqlalchemy import (
    String,
    Numeric,
    Integer,
    Float,
    DateTime,
    ForeignKey,
    Enum as SQLAlchemyEnum,
    UniqueConstraint
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import TenantModel
from app.core.enums import TripStatus, CargoType, TripCostType


class Trip(TenantModel):
    __tablename__ = "trips"

    __table_args__ = (
        UniqueConstraint("tenant_id", "trip_number", name="uq_trip_tenant_number"),
    )

    trip_number: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        index=True
    )

    truck_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("vehicles.id"),
        nullable=False,
        index=True
    )

    trailer_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("vehicles.id"),
        nullable=True
    )

    driver_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("drivers.id"),
        nullable=True
    )

    customer_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("customers.id"),
        nullable=False,
        index=True
    )

    origin: Mapped[str] = mapped_column(
        String(255),
        nullable=False
    )

    destination: Mapped[str] = mapped_column(
        String(255),
        nullable=False
    )

    cargo_type: Mapped[CargoType] = mapped_column(
        SQLAlchemyEnum(CargoType, native_enum=False),
        nullable=False
    )

    cargo_weight_tonnes: Mapped[float] = mapped_column(
        Numeric(10, 2),
        nullable=False
    )

    cargo_volume_m3: Mapped[float | None] = mapped_column(
        Numeric(10, 2),
        nullable=True
    )

    revenue: Mapped[float] = mapped_column(
        Numeric(12, 2),
        default=0.0,
        nullable=False
    )

    status: Mapped[TripStatus] = mapped_column(
        SQLAlchemyEnum(TripStatus, native_enum=False),
        default=TripStatus.DRAFT,
        nullable=False,
        index=True
    )

    planned_start: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False
    )

    actual_start: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True
    )

    planned_end: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False
    )

    actual_end: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True
    )

    truck: Mapped["Vehicle"] = relationship(foreign_keys=[truck_id])
    driver: Mapped["Driver | None"] = relationship()
    customer: Mapped["Customer"] = relationship()
    stops: Mapped[list["TripStop"]] = relationship(back_populates="trip", cascade="all, delete-orphan")
    costs: Mapped[list["TripCost"]] = relationship(back_populates="trip", cascade="all, delete-orphan")
    pod: Mapped["ProofOfDelivery | None"] = relationship(back_populates="trip", uselist=False)


class TripStop(TenantModel):
    __tablename__ = "trip_stops"

    trip_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("trips.id"),
        nullable=False,
        index=True
    )

    stop_order: Mapped[int] = mapped_column(
        Integer,
        nullable=False
    )

    location_name: Mapped[str] = mapped_column(
        String(255),
        nullable=False
    )

    stop_type: Mapped[str] = mapped_column(
        String(50),
        default="WAYPOINT",
        nullable=False
    )

    arrival_time: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True
    )

    departure_time: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True
    )

    trip: Mapped["Trip"] = relationship(back_populates="stops")


class TripCost(TenantModel):
    __tablename__ = "trip_costs"

    trip_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("trips.id"),
        nullable=False,
        index=True
    )

    cost_type: Mapped[TripCostType] = mapped_column(
        SQLAlchemyEnum(TripCostType, native_enum=False),
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

    receipt_photo_url: Mapped[str | None] = mapped_column(
        String(500),
        nullable=True
    )

    notes: Mapped[str | None] = mapped_column(
        String(255),
        nullable=True
    )

    trip: Mapped["Trip"] = relationship(back_populates="costs")


class ProofOfDelivery(TenantModel):
    __tablename__ = "proof_of_deliveries"

    trip_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("trips.id"),
        nullable=False,
        unique=True
    )

    recipient_name: Mapped[str] = mapped_column(
        String(150),
        nullable=False
    )

    signature_url: Mapped[str] = mapped_column(
        String(500),
        nullable=False
    )

    delivery_photo_url: Mapped[str | None] = mapped_column(
        String(500),
        nullable=True
    )

    delivered_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False
    )

    gps_latitude: Mapped[float | None] = mapped_column(
        Float,
        nullable=True
    )

    gps_longitude: Mapped[float | None] = mapped_column(
        Float,
        nullable=True
    )

    trip: Mapped["Trip"] = relationship(back_populates="pod")

