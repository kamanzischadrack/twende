import uuid
from sqlalchemy import (
    String,
    Integer,
    Numeric,
    ForeignKey
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import TenantModel


class FuelRecord(TenantModel):
    __tablename__ = "fuel_records"

    vehicle_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("vehicles.id"),
        nullable=False,
        index=True
    )

    contract_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("contracts.id"),
        nullable=True
    )

    trip_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("trips.id"),
        nullable=True
    )

    litres: Mapped[float] = mapped_column(
        Numeric(8, 2),
        nullable=False
    )

    cost: Mapped[float] = mapped_column(
        Numeric(12, 2),
        nullable=False
    )

    odometer_at_fueling: Mapped[int | None] = mapped_column(
        Integer,
        nullable=True
    )

    source: Mapped[str] = mapped_column(
        String(50),
        default="MANUAL",
        nullable=False
    )

    receipt_photo_url: Mapped[str | None] = mapped_column(
        String(500),
        nullable=True
    )

    vehicle: Mapped["Vehicle"] = relationship()


class MileageRecord(TenantModel):
    __tablename__ = "mileage_records"

    vehicle_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("vehicles.id"),
        nullable=False,
        index=True
    )

    contract_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("contracts.id"),
        nullable=True
    )

    trip_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("trips.id"),
        nullable=True
    )

    odometer_reading: Mapped[int] = mapped_column(
        Integer,
        nullable=False
    )

    source: Mapped[str] = mapped_column(
        String(50),
        default="MANUAL",
        nullable=False
    )

    vehicle: Mapped["Vehicle"] = relationship()

