import uuid
from datetime import date
from sqlalchemy import (
    String,
    Date,
    Numeric,
    JSON,
    ForeignKey,
    Enum as SQLAlchemyEnum
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import TenantModel
from app.core.enums import DamageType, DamageSeverity, DamageStatus, DamageLiability


class DamageRecord(TenantModel):
    __tablename__ = "damage_records"

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

    customer_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("customers.id"),
        nullable=True
    )

    discovery_date: Mapped[date] = mapped_column(
        Date,
        nullable=False
    )

    damage_type: Mapped[DamageType] = mapped_column(
        SQLAlchemyEnum(DamageType, native_enum=False),
        nullable=False
    )

    location_on_vehicle: Mapped[str] = mapped_column(
        String(100),
        nullable=False
    )

    severity: Mapped[DamageSeverity] = mapped_column(
        SQLAlchemyEnum(DamageSeverity, native_enum=False),
        default=DamageSeverity.LOW,
        nullable=False
    )

    photos: Mapped[list[str]] = mapped_column(
        JSON,
        default=list,
        nullable=False
    )

    estimated_repair_cost: Mapped[float] = mapped_column(
        Numeric(12, 2),
        default=0.0,
        nullable=False
    )

    actual_repair_cost: Mapped[float] = mapped_column(
        Numeric(12, 2),
        default=0.0,
        nullable=False
    )

    liability: Mapped[DamageLiability] = mapped_column(
        SQLAlchemyEnum(DamageLiability, native_enum=False),
        default=DamageLiability.CUSTOMER,
        nullable=False
    )

    status: Mapped[DamageStatus] = mapped_column(
        SQLAlchemyEnum(DamageStatus, native_enum=False),
        default=DamageStatus.REPORTED,
        nullable=False,
        index=True
    )

    vehicle: Mapped["Vehicle"] = relationship()
    contract: Mapped["Contract | None"] = relationship()
    customer: Mapped["Customer | None"] = relationship()
    claim: Mapped["InsuranceClaim | None"] = relationship(back_populates="damage_record", uselist=False)

