from sqlalchemy import String, Integer, Numeric, Enum as SQLAlchemyEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import TenantModel
from app.core.enums import VehicleClass, BodyType, TransmissionType, FuelType


class VehicleCategory(TenantModel):
    __tablename__ = "vehicle_categories"

    name: Mapped[str] = mapped_column(
        String(100),
        nullable=False
    )

    vehicle_class: Mapped[VehicleClass] = mapped_column(
        SQLAlchemyEnum(VehicleClass, native_enum=False),
        default=VehicleClass.CAR,
        nullable=False
    )

    body_type: Mapped[BodyType] = mapped_column(
        SQLAlchemyEnum(BodyType, native_enum=False),
        nullable=False
    )

    seats: Mapped[int | None] = mapped_column(
        Integer,
        nullable=True
    )

    doors: Mapped[int | None] = mapped_column(
        Integer,
        nullable=True
    )

    payload_capacity_tonnes: Mapped[float | None] = mapped_column(
        Numeric(10, 2),
        nullable=True
    )

    cargo_volume_m3: Mapped[float | None] = mapped_column(
        Numeric(10, 2),
        nullable=True
    )

    transmission: Mapped[TransmissionType] = mapped_column(
        SQLAlchemyEnum(TransmissionType, native_enum=False),
        default=TransmissionType.AUTOMATIC,
        nullable=False
    )

    fuel_type: Mapped[FuelType] = mapped_column(
        SQLAlchemyEnum(FuelType, native_enum=False),
        default=FuelType.PETROL,
        nullable=False
    )

    description: Mapped[str | None] = mapped_column(
        String(500),
        nullable=True
    )

    vehicles: Mapped[list["Vehicle"]] = relationship(
        back_populates="category"
    )

    rate_plans: Mapped[list["RatePlan"]] = relationship(
        back_populates="category"
    )

