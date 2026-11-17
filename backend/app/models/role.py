
from sqlalchemy import (
    String,
    Text,
    UniqueConstraint,
    Enum as SQLAlchemyEnum
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import TenantModel
from app.core.enums import RoleDevice


class Role(TenantModel):
    __tablename__ = "roles"

    __table_args__ = (
        UniqueConstraint(
            "tenant_id",
            "code",
            name="uq_role_tenant_code"
        ),
    )

    code: Mapped[str] = mapped_column(
        String(100),
        nullable=False
    )

    name: Mapped[str] = mapped_column(
        String(100),
        nullable=False
    )

    description: Mapped[str | None] = mapped_column(
        Text,
        nullable=True
    )

    primary_device: Mapped[RoleDevice] = mapped_column(
        SQLAlchemyEnum(RoleDevice, native_enum=False),
        nullable=False
    )

    user_links: Mapped[list["UserRole"]] = relationship(
        back_populates="role",
        cascade="all, delete-orphan"
    )

    permission_links: Mapped[list["RolePermission"]] = relationship(
        back_populates="role",
        cascade="all, delete-orphan"
    )
