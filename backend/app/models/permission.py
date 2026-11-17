
from sqlalchemy import String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import TenantModel


class Permission(TenantModel):
    __tablename__ = "permissions"

    __table_args__ = (
        UniqueConstraint("tenant_id", "key", name="uq_permission_tenant_key"),
    )

    key: Mapped[str] = mapped_column(
        String(150),
        nullable=False
    )

    resource: Mapped[str] = mapped_column(
        String(100),
        nullable=False
    )

    action: Mapped[str] = mapped_column(
        String(100),
        nullable=False
    )

    description: Mapped[str | None] = mapped_column(
        Text,
        nullable=True
    )

    role_links: Mapped[list["RolePermission"]] = relationship(
        back_populates="permission"
    )
