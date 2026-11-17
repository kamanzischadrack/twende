import uuid
from datetime import date
from sqlalchemy import (
    String,
    Date,
    JSON,
    ForeignKey
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import TenantModel


class CustomerDriver(TenantModel):
    __tablename__ = "customer_drivers"

    customer_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("customers.id"),
        nullable=False,
        index=True
    )

    full_name: Mapped[str] = mapped_column(
        String(150),
        nullable=False
    )

    phone: Mapped[str] = mapped_column(
        String(30),
        nullable=False
    )

    licence_number: Mapped[str] = mapped_column(
        String(50),
        nullable=False
    )

    licence_expiry_date: Mapped[date] = mapped_column(
        Date,
        nullable=False
    )

    licence_classes: Mapped[list[str]] = mapped_column(
        JSON,
        default=list,
        nullable=False
    )

    customer: Mapped["Customer"] = relationship(
        back_populates="drivers"
    )

