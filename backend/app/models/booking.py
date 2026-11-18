import uuid
from datetime import datetime
from sqlalchemy import (
    String,
    Numeric,
    Integer,
    DateTime,
    ForeignKey,
    Enum as SQLAlchemyEnum,
    UniqueConstraint
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.models.base import TenantModel
from app.core.enums import BookingStatus, BookingSource, RentalType


class Booking(TenantModel):
    __tablename__ = "bookings"

    __table_args__ = (
        UniqueConstraint("tenant_id", "booking_number", name="uq_booking_tenant_number"),
    )

    booking_number: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        index=True
    )

    customer_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("customers.id"),
        nullable=False,
        index=True
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

    pickup_branch_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("branches.id"),
        nullable=False
    )

    return_branch_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("branches.id"),
        nullable=True
    )

    status: Mapped[BookingStatus] = mapped_column(
        SQLAlchemyEnum(BookingStatus, native_enum=False),
        default=BookingStatus.DRAFT,
        nullable=False,
        index=True
    )

    source: Mapped[BookingSource] = mapped_column(
        SQLAlchemyEnum(BookingSource, native_enum=False),
        default=BookingSource.WALK_IN,
        nullable=False
    )

    rental_type: Mapped[RentalType] = mapped_column(
        SQLAlchemyEnum(RentalType, native_enum=False),
        default=RentalType.SELF_DRIVE,
        nullable=False
    )

    start_datetime: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False
    )

    end_datetime: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False
    )

    quoted_amount: Mapped[float] = mapped_column(
        Numeric(12, 2),
        default=0.0,
        nullable=False
    )

    estimated_mileage: Mapped[int | None] = mapped_column(
        Integer,
        nullable=True
    )

    notes: Mapped[str | None] = mapped_column(
        String(500),
        nullable=True
    )

    customer: Mapped["Customer"] = relationship()
    category: Mapped["VehicleCategory"] = relationship()
    vehicle: Mapped["Vehicle | None"] = relationship()
    pickup_branch: Mapped["Branch"] = relationship(foreign_keys=[pickup_branch_id])
    contract: Mapped["Contract | None"] = relationship(back_populates="booking", uselist=False)

