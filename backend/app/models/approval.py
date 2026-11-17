import uuid
from datetime import datetime
from sqlalchemy import String, Text, DateTime, ForeignKey, Enum as SQLAlchemyEnum
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import TenantModel, current_time
from app.core.enums import ApprovalDecision


class Approval(TenantModel):
    __tablename__ = "approvals"

    target_type: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        index=True
    )

    target_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        nullable=False,
        index=True
    )

    requested_by_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id"),
        nullable=False
    )

    approver_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id"),
        nullable=True
    )

    decision: Mapped[ApprovalDecision] = mapped_column(
        SQLAlchemyEnum(ApprovalDecision, native_enum=False),
        default=ApprovalDecision.PENDING,
        nullable=False,
        index=True
    )

    reason: Mapped[str] = mapped_column(
        String(255),
        nullable=False
    )

    comment: Mapped[str | None] = mapped_column(
        Text,
        nullable=True
    )

    requested_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=current_time,
        nullable=False
    )

    resolved_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True
    )

    requested_by: Mapped["User"] = relationship(foreign_keys=[requested_by_id])
    approver: Mapped["User | None"] = relationship(foreign_keys=[approver_id])

