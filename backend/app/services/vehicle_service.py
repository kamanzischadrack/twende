from uuid import UUID
from sqlalchemy import select
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError

from app.models.vehicle_category import VehicleCategory
from app.models.vehicle import Vehicle
from app.core.enums import VehicleStatus
from app.schemas.vehicle_category import VehicleCategoryCreate, VehicleCategoryUpdate
from app.schemas.vehicle import VehicleCreate, VehicleUpdate, VehicleStatusOverride


def create_vehicle_category(db: Session, tenant_id: UUID, data: VehicleCategoryCreate) -> VehicleCategory:
    category = VehicleCategory(**data.model_dump(), tenant_id=tenant_id)
    db.add(category)
    db.commit()
    db.refresh(category)
    return category


def get_vehicle_category(db: Session, tenant_id: UUID, category_id: UUID) -> VehicleCategory | None:
    return db.scalar(select(VehicleCategory).where(VehicleCategory.id == category_id, VehicleCategory.tenant_id == tenant_id))


def list_vehicle_categories(db: Session, tenant_id: UUID, skip: int = 0, limit: int = 50) -> list[VehicleCategory]:
    stmt = select(VehicleCategory).where(VehicleCategory.tenant_id == tenant_id).order_by(VehicleCategory.name).offset(skip).limit(limit)
    return list(db.scalars(stmt).all())


def update_vehicle_category(db: Session, tenant_id: UUID, category_id: UUID, data: VehicleCategoryUpdate) -> VehicleCategory | None:
    category = get_vehicle_category(db, tenant_id, category_id)
    if not category:
        return None
    for key, value in data.model_dump(exclude_unset=True).items():
        setattr(category, key, value)
    db.commit()
    db.refresh(category)
    return category


def delete_vehicle_category(db: Session, tenant_id: UUID, category_id: UUID) -> bool:
    category = get_vehicle_category(db, tenant_id, category_id)
    if not category:
        return False
    try:
        db.delete(category)
        db.commit()
        return True
    except IntegrityError:
        db.rollback()
        raise ValueError("Cannot delete category in use by vehicles or rate plans.")


def create_vehicle(db: Session, tenant_id: UUID, data: VehicleCreate) -> Vehicle:
    values = data.model_dump()
    values["plate_number"] = values["plate_number"].strip().upper()
    vehicle = Vehicle(**values, tenant_id=tenant_id, status=VehicleStatus.AVAILABLE)
    try:
        db.add(vehicle)
        db.commit()
        db.refresh(vehicle)
        return vehicle
    except IntegrityError:
        db.rollback()
        raise ValueError(f"Vehicle plate '{values['plate_number']}' already exists.")


def get_vehicle(db: Session, tenant_id: UUID, vehicle_id: UUID) -> Vehicle | None:
    return db.scalar(select(Vehicle).where(Vehicle.id == vehicle_id, Vehicle.tenant_id == tenant_id))


def list_vehicles(
    db: Session,
    tenant_id: UUID,
    branch_id: UUID | None = None,
    category_id: UUID | None = None,
    status: VehicleStatus | None = None,
    skip: int = 0,
    limit: int = 50
) -> list[Vehicle]:
    query = select(Vehicle).where(Vehicle.tenant_id == tenant_id)
    if branch_id:
        query = query.where(Vehicle.branch_id == branch_id)
    if category_id:
        query = query.where(Vehicle.category_id == category_id)
    if status:
        query = query.where(Vehicle.status == status)
    return list(db.scalars(query.order_by(Vehicle.plate_number).offset(skip).limit(limit)).all())


def update_vehicle(db: Session, tenant_id: UUID, vehicle_id: UUID, data: VehicleUpdate) -> Vehicle | None:
    vehicle = get_vehicle(db, tenant_id, vehicle_id)
    if not vehicle:
        return None
    values = data.model_dump(exclude_unset=True)
    if "plate_number" in values and values["plate_number"]:
        values["plate_number"] = values["plate_number"].strip().upper()
    for key, value in values.items():
        setattr(vehicle, key, value)
    db.commit()
    db.refresh(vehicle)
    return vehicle


def override_vehicle_status(db: Session, tenant_id: UUID, vehicle_id: UUID, override: VehicleStatusOverride) -> Vehicle:
    vehicle = get_vehicle(db, tenant_id, vehicle_id)
    if not vehicle:
        raise ValueError("Vehicle not found.")
    vehicle.status = override.new_status
    vehicle.status_reason = f"Manual override: {override.reason}"
    db.commit()
    db.refresh(vehicle)
    return vehicle
