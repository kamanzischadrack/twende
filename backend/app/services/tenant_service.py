from uuid import UUID

from sqlalchemy import select, true
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError

from app.models.tenant import Tenant
from app.schemas.tenant import TenantCreate, TenantUpdate
from app.services.access_control_seed_service import seed_access_control


def create_tenant(db: Session, tenant_data: TenantCreate):
    try:
        tenant = Tenant(**tenant_data.model_dump())

        db.add(tenant)

        db.flush()

        seed_access_control(db, tenant.id)

        db.refresh(tenant)

        return tenant

    except Exception:
        db.rollback()
        raise


def get_tenant(db: Session, tenant_id: UUID):
    return db.get(Tenant, tenant_id)


def get_tenants(db: Session, skip: int = 0, limit: int = 20):
    statement = (select(Tenant).order_by(Tenant.created_at).offset(skip).limit(limit))
    return db.scalars(statement).all()


def update_tenant(db: Session, tenant_id: UUID, tenant_data: TenantUpdate):
    tenant = db.get(Tenant, tenant_id)
    if tenant is None:
        return None
    updated_data = tenant_data.model_dump(exclude_unset=True)

    for key, value in updated_data.items():
        setattr(tenant, key, value)
    db.commit()
    db.refresh(tenant)

    return tenant


def delete_tenant(db: Session, tenant_id: UUID):
    tenant = db.get(Tenant, tenant_id)

    if tenant is None:
        return False

    try:
        db.delete(tenant)
        db.commit()

    except IntegrityError:
        db.rollback()
        raise ValueError("Cannot delete this tenant because other records depend on it ")

    return true
