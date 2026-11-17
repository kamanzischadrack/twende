import uuid
from datetime import date
from sqlalchemy import (
    String,
    Text,
    Date,
    Numeric,
    Integer,
    ForeignKey,
    Enum as SQLAlchemyEnum,
    UniqueConstraint
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import TenantModel
from app.core.enums import WorkOrderType, WorkOrderStatus


class WorkOrder(TenantModel):
    __tablename__ = "work_orders"

    __table_args__ = (
        UniqueConstraint("tenant_id", "order_number", name="uq_work_order_tenant_number"),
    )

    order_number: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        index=True
    )

    vehicle_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("vehicles.id"),
        nullable=False,
        index=True
    )

    damage_record_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("damage_records.id"),
        nullable=True
    )

    order_type: Mapped[WorkOrderType] = mapped_column(
        SQLAlchemyEnum(WorkOrderType, native_enum=False),
        default=WorkOrderType.PREVENTIVE,
        nullable=False
    )

    garage_name: Mapped[str] = mapped_column(
        String(150),
        nullable=False
    )

    description: Mapped[str] = mapped_column(
        Text,
        nullable=False
    )

    start_date: Mapped[date] = mapped_column(
        Date,
        nullable=False
    )

    estimated_completion_date: Mapped[date | None] = mapped_column(
        Date,
        nullable=True
    )

    actual_completion_date: Mapped[date | None] = mapped_column(
        Date,
        nullable=True
    )

    parts_cost: Mapped[float] = mapped_column(
        Numeric(12, 2),
        default=0.0,
        nullable=False
    )

    labour_cost: Mapped[float] = mapped_column(
        Numeric(12, 2),
        default=0.0,
        nullable=False
    )

    total_cost: Mapped[float] = mapped_column(
        Numeric(12, 2),
        default=0.0,
        nullable=False
    )

    downtime_hours: Mapped[int] = mapped_column(
        Integer,
        default=0,
        nullable=False
    )

    status: Mapped[WorkOrderStatus] = mapped_column(
        SQLAlchemyEnum(WorkOrderStatus, native_enum=False),
        default=WorkOrderStatus.DRAFT,
        nullable=False,
        index=True
    )

    vehicle: Mapped["Vehicle"] = relationship()
    damage_record: Mapped["DamageRecord | None"] = relationship()

