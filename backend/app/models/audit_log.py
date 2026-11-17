import uuid
from sqlalchemy import String, JSON, ForeignKey, Enum as SQLAlchemyEnum
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import TenantModel
from app.core.enums import AuditAction


class AuditLog(TenantModel):
    __tablename__ = "audit_logs"

    user_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id"),
        nullable=True,
        index=True
    )

    action: Mapped[AuditAction] = mapped_column(
        SQLAlchemyEnum(AuditAction, native_enum=False),
        nullable=False,
        index=True
    )

    entity_name: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        index=True
    )

    entity_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        nullable=True,
        index=True
    )

    before_state: Mapped[dict | None] = mapped_column(
        JSON,
        nullable=True
    )

    after_state: Mapped[dict | None] = mapped_column(
        JSON,
        nullable=True
    )

    ip_address: Mapped[str | None] = mapped_column(
        String(45),
        nullable=True
    )

    device: Mapped[str | None] = mapped_column(
        String(255),
        nullable=True
    )

    user: Mapped["User | None"] = relationship()

