import uuid

from sqlalchemy import (String,
                        Boolean,
                        ForeignKey,
                        Enum as SQLAlchemyEnum,
                        UniqueConstraint)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import TenantModel
from app.core.enums import UserStatus


class User(TenantModel):
    __tablename__ = "users"

    __table_args__ = (
        UniqueConstraint("tenant_id", "phone", name="uq_user_tenant_phone"),
        UniqueConstraint("tenant_id", "email", name="uq_user_tenant_email"),
    )

    name: Mapped[str] = mapped_column(
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

    password_hash: Mapped[str] = mapped_column(
        String(255),
        nullable=False
    )

    two_factor_enabled: Mapped[bool] = mapped_column(
        Boolean,
        default=False,
        nullable=False
    )

    two_factor_secret: Mapped[str | None] = mapped_column(
        String(255),
        nullable=True
    )

    status: Mapped[UserStatus] = mapped_column(
        SQLAlchemyEnum(UserStatus, native_enum=False),
        default=UserStatus.ACTIVE,
        nullable=False
    )

    branch_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("branches.id"),
        nullable=True
    )

    branch: Mapped["Branch | None"] = relationship()

    role_links: Mapped[list["UserRole"]] = relationship(
        back_populates="user",
        cascade="all, delete-orphan"
    )
