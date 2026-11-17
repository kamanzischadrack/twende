import uuid
from datetime import date
from sqlalchemy import (
    String,
    Date,
    Numeric,
    ForeignKey,
    Enum as SQLAlchemyEnum
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import TenantModel
from app.core.enums import ClaimStatus


class InsurancePolicy(TenantModel):
    __tablename__ = "insurance_policies"

    vehicle_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("vehicles.id"),
        nullable=False,
        index=True
    )

    insurer_name: Mapped[str] = mapped_column(
        String(150),
        nullable=False
    )

    policy_number: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
        index=True
    )

    cover_type: Mapped[str] = mapped_column(
        String(100),
        default="COMPREHENSIVE",
        nullable=False
    )

    premium_amount: Mapped[float] = mapped_column(
        Numeric(12, 2),
        nullable=False
    )

    start_date: Mapped[date] = mapped_column(
        Date,
        nullable=False
    )

    expiry_date: Mapped[date] = mapped_column(
        Date,
        nullable=False,
        index=True
    )

    vehicle: Mapped["Vehicle"] = relationship()
    claims: Mapped[list["InsuranceClaim"]] = relationship(back_populates="policy")


class InsuranceClaim(TenantModel):
    __tablename__ = "insurance_claims"

    policy_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("insurance_policies.id"),
        nullable=False,
        index=True
    )

    damage_record_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("damage_records.id"),
        nullable=True
    )

    claim_number: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
        index=True
    )

    amount_claimed: Mapped[float] = mapped_column(
        Numeric(12, 2),
        nullable=False
    )

    amount_approved: Mapped[float] = mapped_column(
        Numeric(12, 2),
        default=0.0,
        nullable=False
    )

    claim_date: Mapped[date] = mapped_column(
        Date,
        nullable=False
    )

    status: Mapped[ClaimStatus] = mapped_column(
        SQLAlchemyEnum(ClaimStatus, native_enum=False),
        default=ClaimStatus.SUBMITTED,
        nullable=False
    )

    notes: Mapped[str | None] = mapped_column(
        String(500),
        nullable=True
    )

    policy: Mapped["InsurancePolicy"] = relationship(back_populates="claims")
    damage_record: Mapped["DamageRecord | None"] = relationship(back_populates="claim")

