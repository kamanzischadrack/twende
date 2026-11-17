from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError

from app.models.role import Role
from app.schemas.role import RoleCreate, RoleUpdate


def create_role(
        db: Session,
        tenant_id: UUID,
        role_data: RoleCreate
):
    role = Role(
        **role_data.model_dump(),
        tenant_id=tenant_id
    )

    try:
        db.add(role)
        db.commit()
        db.refresh(role)

    except IntegrityError:
        db.rollback()
        raise ValueError(
            "A role with this code already exists in this tenant."
        )

    return role


def get_roles(
        db: Session,
        tenant_id: UUID,
        skip: int = 0,
        limit: int = 100
):
    statement = (
        select(Role)
        .where(Role.tenant_id == tenant_id)
        .order_by(Role.created_at.desc())
        .offset(skip)
        .limit(limit)
    )

    return db.scalars(statement).all()


def get_role(
        db: Session,
        tenant_id: UUID,
        role_id: UUID
):
    statement = select(Role).where(
        Role.id == role_id,
        Role.tenant_id == tenant_id
    )

    return db.scalar(statement)


def update_role(
        db: Session,
        tenant_id: UUID,
        role_id: UUID,
        role_data: RoleUpdate
):
    role = get_role(db, tenant_id, role_id)

    if role is None:
        return None

    update_data = role_data.model_dump(exclude_unset=True)

    for key, value in update_data.items():
        setattr(role, key, value)

    try:
        db.commit()
        db.refresh(role)

    except IntegrityError:
        db.rollback()
        raise ValueError(
            "A role with this code already exists in this tenant."
        )

    return role


def delete_role(
        db: Session,
        tenant_id: UUID,
        role_id: UUID
):
    role = get_role(db, tenant_id, role_id)

    if role is None:
        return False

    db.delete(role)
    db.commit()

    return True
