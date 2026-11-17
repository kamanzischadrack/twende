from sqlalchemy import String, JSON, Enum as SQLAlchemyEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.models.base import BaseModel
from app.core.enums import TenantStatus


class Tenant(BaseModel):
    __tablename__ = "tenants"

    name: Mapped[str] = mapped_column(
        String(150),
        nullable=False
    )

    country: Mapped[str] = mapped_column(
        String(200),
        nullable=False,
        default="Rwanda"
    )

    currency: Mapped[str] = mapped_column(
        String(3),
        nullable=False,
        default="RWF"
    )

    status: Mapped[TenantStatus] = mapped_column(
        SQLAlchemyEnum(TenantStatus, native_enum=False),
        nullable=False,
        default=TenantStatus.PENDING_APPROVAL
    )

    contact_email: Mapped[str | None] = mapped_column(
        String(150),
        nullable=True
    )

    contact_phone: Mapped[str | None] = mapped_column(
        String(30),
        nullable=True
    )

    tin_number: Mapped[str | None] = mapped_column(
        String(50),
        nullable=True
    )

    invitation_token: Mapped[str | None] = mapped_column(
        String(255),
        nullable=True,
        index=True
    )

    tax_settings: Mapped[dict] = mapped_column(
        JSON,
        nullable=False,
        default=dict
    )

    branches: Mapped[list["Branch"]] = relationship(
        back_populates="tenant"
    )
