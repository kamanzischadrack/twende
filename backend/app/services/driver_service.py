import uuid
from sqlalchemy.orm import Session
from sqlalchemy import select
from fastapi import HTTPException, status

from app.models.driver import Driver, DriverAssignment
from app.core.enums import DriverStatus, AssignmentStatus
from app.schemas.driver import DriverCreate, DriverUpdate


def create_driver(db: Session, tenant_id: uuid.UUID, data: DriverCreate) -> Driver:
    existing = db.execute(
        select(Driver).where(
            Driver.tenant_id == tenant_id,
            Driver.licence_number == data.licence_number,
        )
    ).scalar_one_or_none()

    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Driver with licence {data.licence_number} already registered",
        )

    driver = Driver(
        tenant_id=tenant_id,
        full_name=data.full_name,
        phone=data.phone,
        email=data.email,
        licence_number=data.licence_number,
        licence_classes=data.licence_classes,
        licence_expiry_date=data.licence_expiry_date,
        daily_rate=data.daily_rate,
        status=DriverStatus.AVAILABLE,
    )
    db.add(driver)
    db.commit()
    db.refresh(driver)
    return driver


def list_drivers(
    db: Session,
    tenant_id: uuid.UUID,
    status_filter: DriverStatus | None = None,
) -> list[Driver]:
    query = select(Driver).where(Driver.tenant_id == tenant_id)
    if status_filter:
        query = query.where(Driver.status == status_filter)
    return list(db.execute(query).scalars().all())


def update_driver(
    db: Session,
    tenant_id: uuid.UUID,
    driver_id: uuid.UUID,
    data: DriverUpdate,
) -> Driver:
    driver = db.execute(
        select(Driver).where(
            Driver.id == driver_id,
            Driver.tenant_id == tenant_id,
        )
    ).scalar_one_or_none()

    if not driver:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Driver not found")

    for k, v in data.model_dump(exclude_unset=True).items():
        setattr(driver, k, v)

    db.commit()
    db.refresh(driver)
    return driver

