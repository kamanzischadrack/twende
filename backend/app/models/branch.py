from sqlalchemy import String, Float, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.models.base import TenantModel


class Branch(TenantModel):
    __tablename__ = "branches"

    name: Mapped[str] = mapped_column(
        String(150),
        nullable=False
    )

    address: Mapped[str] = mapped_column(
        String(255),
        nullable=False
    )

    latitude: Mapped[float | None] = mapped_column(
        Float,
        nullable=True
    )

    longitude: Mapped[float | None] = mapped_column(
        Float,
        nullable=True
    )

    opening_hours: Mapped[dict] = mapped_column(
        JSON,
        nullable=False,
        default=dict
    )

    tenant: Mapped["Tenant"] = relationship(
        back_populates="branches"
    )

    locations: Mapped[list["Location"]] = relationship(
        back_populates="branch"
    )