import uuid
from datetime import date, datetime
from sqlalchemy import (
    String,
    Date,
    DateTime,
    Numeric,
    JSON,
    ForeignKey,
    Enum as SQLAlchemyEnum,
    UniqueConstraint
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import TenantModel
from app.core.enums import DriverStatus, AssignmentStatus


class Driver(TenantModel):
    __tablename__ = "drivers"

    __table_args__ = (
        UniqueConstraint("tenant_id", "licence_number", name="uq_driver_tenant_licence"),
    )

    full_name: Mapped[str] = mapped_column(
        String(150),
        nullable=False
    )

    phone: Mapped[str] = mapped_column(
        String(30),
        nullable=False
    )

    email: Mapped[str | None] = mapped_column(
        String(150),
        nullable=True
    )

    licence_number: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        index=True
    )

    licence_classes: Mapped[list[str]] = mapped_column(
        JSON,
        default=list,
        nullable=False
    )

    licence_expiry_date: Mapped[date] = mapped_column(
        Date,
        nullable=False
    )

    daily_rate: Mapped[float] = mapped_column(
        Numeric(10, 2),
        default=0.0,
        nullable=False
    )

    status: Mapped[DriverStatus] = mapped_column(
        SQLAlchemyEnum(DriverStatus, native_enum=False),
        default=DriverStatus.AVAILABLE,
        nullable=False
    )

    branch_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("branches.id"),
        nullable=True
    )

    user_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id"),
        nullable=True
    )

    branch: Mapped["Branch | None"] = relationship()
    user: Mapped["User | None"] = relationship()
    assignments: Mapped[list["DriverAssignment"]] = relationship(back_populates="driver")


class DriverAssignment(TenantModel):
    __tablename__ = "driver_assignments"

    driver_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("drivers.id"),
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

    start_time: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False
    )

    end_time: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False
    )

    status: Mapped[AssignmentStatus] = mapped_column(
        SQLAlchemyEnum(AssignmentStatus, native_enum=False),
        default=AssignmentStatus.SCHEDULED,
        nullable=False
    )

    driver: Mapped["Driver"] = relationship(back_populates="assignments")

