import uuid
from datetime import date
from sqlalchemy import String, Date, Numeric, Boolean, Text, ForeignKey, Enum as SQLAlchemyEnum
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import TenantModel
from app.core.enums import IncidentType, IncidentStatus


class Incident(TenantModel):
    __tablename__ = "incidents"

    incident_number: Mapped[str] = mapped_column(
        String(50),
        unique=True,
        index=True,
        nullable=False
    )

    vehicle_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("vehicles.id"),
        nullable=False,
        index=True
    )

    contract_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("contracts.id"),
        nullable=True,
        index=True
    )

    driver_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("drivers.id"),
        nullable=True,
        index=True
    )

    incident_type: Mapped[IncidentType] = mapped_column(
        SQLAlchemyEnum(IncidentType, native_enum=False),
        nullable=False
    )

    incident_date: Mapped[date] = mapped_column(
        Date,
        nullable=False
    )

    location: Mapped[str] = mapped_column(
        String(255),
        nullable=False
    )

    evidence_url: Mapped[str | None] = mapped_column(
        String(500),
        nullable=True
    )

    police_report_number: Mapped[str | None] = mapped_column(
        String(100),
        nullable=True
    )

    police_report_url: Mapped[str | None] = mapped_column(
        String(500),
        nullable=True
    )

    fine_amount: Mapped[float] = mapped_column(
        Numeric(12, 2),
        default=0.0,
        nullable=False
    )

    is_recharged_to_customer: Mapped[bool] = mapped_column(
        Boolean,
        default=False,
        nullable=False
    )

    status: Mapped[IncidentStatus] = mapped_column(
        SQLAlchemyEnum(IncidentStatus, native_enum=False),
        default=IncidentStatus.REPORTED,
        nullable=False,
        index=True
    )

    resolution_notes: Mapped[str | None] = mapped_column(
        Text,
        nullable=True
    )

    vehicle: Mapped["Vehicle"] = relationship()
    contract: Mapped["Contract | None"] = relationship()
    driver: Mapped["Driver | None"] = relationship()

