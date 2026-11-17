import uuid
from datetime import date
from sqlalchemy import (
    String,
    Date,
    Boolean,
    ForeignKey,
    Enum as SQLAlchemyEnum
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import TenantModel
from app.core.enums import VehicleDocumentType


class VehicleDocument(TenantModel):
    __tablename__ = "vehicle_documents"

    vehicle_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("vehicles.id"),
        nullable=False,
        index=True
    )

    document_type: Mapped[VehicleDocumentType] = mapped_column(
        SQLAlchemyEnum(VehicleDocumentType, native_enum=False),
        nullable=False
    )

    document_number: Mapped[str] = mapped_column(
        String(100),
        nullable=False
    )

    issue_date: Mapped[date | None] = mapped_column(
        Date,
        nullable=True
    )

    expiry_date: Mapped[date] = mapped_column(
        Date,
        nullable=False,
        index=True
    )

    file_url: Mapped[str | None] = mapped_column(
        String(500),
        nullable=True
    )

    is_critical: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
        nullable=False
    )

    notes: Mapped[str | None] = mapped_column(
        String(500),
        nullable=True
    )

    vehicle: Mapped["Vehicle"] = relationship(
        back_populates="documents"
    )

