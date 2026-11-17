from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError

from app.models.permission import Permission
from app.schemas.permission import PermissionCreate, PermissionUpdate
from uuid import UUID

from sqlalchemy import select

from app.models.user_role import UserRole
from app.models.role_permission import RolePermission

def create_permission(
        db: Session,
        tenant_id: UUID,
        permission_data: PermissionCreate
):
    permission = Permission(
        **permission_data.model_dump(),
        tenant_id=tenant_id
    )

    try:
        db.add(permission)
        db.commit()
        db.refresh(permission)

    except IntegrityError:
        db.rollback()
        raise ValueError(
            "A permission with this key already exists in this tenant."
        )

    return permission


def get_permissions(
        db: Session,
        tenant_id: UUID,
        skip: int = 0,
        limit: int = 100
):
    statement = (
        select(Permission)
        .where(Permission.tenant_id == tenant_id)
        .order_by(Permission.created_at.desc())
        .offset(skip)
        .limit(limit)
    )

    return db.scalars(statement).all()


def get_permission(
        db: Session,
        tenant_id: UUID,
        permission_id: UUID
):
    statement = select(Permission).where(
        Permission.id == permission_id,
        Permission.tenant_id == tenant_id
    )

    return db.scalar(statement)


def update_permission(
        db: Session,
        tenant_id: UUID,
        permission_id: UUID,
        permission_data: PermissionUpdate
):
    permission = get_permission(db, tenant_id, permission_id)

    if permission is None:
        return None

    update_data = permission_data.model_dump(exclude_unset=True)

    for key, value in update_data.items():
        setattr(permission, key, value)

    try:
        db.commit()
        db.refresh(permission)

    except IntegrityError:
        db.rollback()
        raise ValueError(
            "A permission with this key already exists in this tenant."
        )

    return permission


def delete_permission(
        db: Session,
        tenant_id: UUID,
        permission_id: UUID
):
    permission = get_permission(db, tenant_id, permission_id)

    if permission is None:
        return False

    db.delete(permission)
    db.commit()

    return True


def user_has_permission(
    db: Session,
    tenant_id: UUID,
    user_id: UUID,
    permission_key: str
) -> bool:

    statement = (
        select(Permission.id)
        .join(
            RolePermission,
            RolePermission.permission_id == Permission.id
        )
        .join(
            UserRole,
            UserRole.role_id == RolePermission.role_id
        )
        .where(
            UserRole.user_id == user_id,
            UserRole.tenant_id == tenant_id,
            RolePermission.tenant_id == tenant_id,
            Permission.tenant_id == tenant_id,
            Permission.key == permission_key
        )
    )

    return db.scalar(statement) is not None