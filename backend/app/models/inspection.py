import uuid
from sqlalchemy import (
    String,
    Integer,
    Numeric,
    JSON,
    ForeignKey,
    Enum as SQLAlchemyEnum
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import TenantModel
from app.core.enums import InspectionType


class Inspection(TenantModel):
    __tablename__ = "inspections"

    contract_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("contracts.id"),
        nullable=True,
        index=True
    )

    trip_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("trips.id"),
        nullable=True,
        index=True
    )

    vehicle_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("vehicles.id"),
        nullable=False,
        index=True
    )

    inspection_type: Mapped[InspectionType] = mapped_column(
        SQLAlchemyEnum(InspectionType, native_enum=False),
        nullable=False
    )

    odometer_reading: Mapped[int] = mapped_column(
        Integer,
        nullable=False
    )

    fuel_fraction: Mapped[float] = mapped_column(
        Numeric(4, 2),
        default=1.0,
        nullable=False
    )

    checklist_data: Mapped[dict] = mapped_column(
        JSON,
        default=dict,
        nullable=False
    )

    signature_url: Mapped[str | None] = mapped_column(
        String(500),
        nullable=True
    )

    photos: Mapped[list[str]] = mapped_column(
        JSON,
        default=list,
        nullable=False
    )

    damage_marks: Mapped[list[dict]] = mapped_column(
        JSON,
        default=list,
        nullable=False
    )

    contract: Mapped["Contract | None"] = relationship(back_populates="inspections")
    vehicle: Mapped["Vehicle"] = relationship()

