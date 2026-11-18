import uuid
from datetime import datetime
from sqlalchemy import (
    String,
    Text,
    Numeric,
    Integer,
    DateTime,
    JSON,
    ForeignKey,
    Enum as SQLAlchemyEnum,
    UniqueConstraint
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.models.base import TenantModel
from app.core.enums import ContractStatus, ContractLineType


class Contract(TenantModel):
    __tablename__ = "contracts"

    __table_args__ = (
        UniqueConstraint("tenant_id", "contract_number", name="uq_contract_tenant_number"),
    )

    contract_number: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        index=True
    )

    booking_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("bookings.id"),
        nullable=True,
        index=True
    )

    customer_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("customers.id"),
        nullable=False,
        index=True
    )

    vehicle_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("vehicles.id"),
        nullable=False,
        index=True
    )

    assigned_driver_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("drivers.id"),
        nullable=True
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

    start_datetime: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False
    )

    expected_return_datetime: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False
    )

    actual_return_datetime: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True
    )

    status: Mapped[ContractStatus] = mapped_column(
        SQLAlchemyEnum(ContractStatus, native_enum=False),
        default=ContractStatus.DRAFT,
        nullable=False,
        index=True
    )

    terms: Mapped[str | None] = mapped_column(
        Text,
        nullable=True
    )

    customer_signature_url: Mapped[str | None] = mapped_column(
        String(500),
        nullable=True
    )

    staff_signature_url: Mapped[str | None] = mapped_column(
        String(500),
        nullable=True
    )

    signed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True
    )

    booking: Mapped["Booking | None"] = relationship(back_populates="contract")
    customer: Mapped["Customer"] = relationship()
    vehicle: Mapped["Vehicle"] = relationship()
    lines: Mapped[list["ContractLine"]] = relationship(back_populates="contract", cascade="all, delete-orphan")
    amendments: Mapped[list["ContractAmendment"]] = relationship(back_populates="contract", cascade="all, delete-orphan")
    inspections: Mapped[list["Inspection"]] = relationship(back_populates="contract")


class ContractLine(TenantModel):
    __tablename__ = "contract_lines"

    contract_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("contracts.id"),
        nullable=False,
        index=True
    )

    line_type: Mapped[ContractLineType] = mapped_column(
        SQLAlchemyEnum(ContractLineType, native_enum=False),
        nullable=False
    )

    description: Mapped[str] = mapped_column(
        String(255),
        nullable=False
    )

    quantity: Mapped[float] = mapped_column(
        Numeric(10, 2),
        default=1.0,
        nullable=False
    )

    unit_price: Mapped[float] = mapped_column(
        Numeric(12, 2),
        nullable=False
    )

    tax_rate: Mapped[float] = mapped_column(
        Numeric(5, 4),
        default=0.18,
        nullable=False
    )

    tax_amount: Mapped[float] = mapped_column(
        Numeric(12, 2),
        default=0.0,
        nullable=False
    )

    total_amount: Mapped[float] = mapped_column(
        Numeric(12, 2),
        nullable=False
    )

    contract: Mapped["Contract"] = relationship(back_populates="lines")


class ContractAmendment(TenantModel):
    __tablename__ = "contract_amendments"

    contract_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("contracts.id"),
        nullable=False,
        index=True
    )

    amendment_number: Mapped[int] = mapped_column(
        Integer,
        nullable=False
    )

    reason: Mapped[str] = mapped_column(
        String(255),
        nullable=False
    )

    changes: Mapped[dict] = mapped_column(
        JSON,
        default=dict,
        nullable=False
    )

    approved_by: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id"),
        nullable=True
    )

    contract: Mapped["Contract"] = relationship(back_populates="amendments")

