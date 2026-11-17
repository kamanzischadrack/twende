from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError

from app.models.role import Role
from app.models.permission import Permission
from app.models.role_permission import RolePermission


def assign_permission_to_role(
    db: Session,
    tenant_id: UUID,
    role_id: UUID,
    permission_id: UUID,
    assigned_by: UUID | None = None
):

    role = db.scalar(
        select(Role).where(
            Role.id == role_id,
            Role.tenant_id == tenant_id
        )
    )

    if role is None:
        raise ValueError("Role not found in this tenant.")


    permission = db.scalar(
        select(Permission).where(
            Permission.id == permission_id,
            Permission.tenant_id == tenant_id
        )
    )

    if permission is None:
        raise ValueError("Permission not found in this tenant.")


    existing_assignment = db.scalar(
        select(RolePermission).where(
            RolePermission.tenant_id == tenant_id,
            RolePermission.role_id == role_id,
            RolePermission.permission_id == permission_id
        )
    )

    if existing_assignment:
        raise ValueError("This permission is already assigned to the role.")


    assignment = RolePermission(
        tenant_id=tenant_id,
        role_id=role_id,
        permission_id=permission_id,
        created_by=assigned_by
    )

    try:
        db.add(assignment)
        db.commit()
        db.refresh(assignment)

    except IntegrityError:
        db.rollback()
        raise ValueError("Could not assign this permission to the role.")

    return permission


def get_role_permissions(
    db: Session,
    tenant_id: UUID,
    role_id: UUID
):

    role = db.scalar(
        select(Role).where(
            Role.id == role_id,
            Role.tenant_id == tenant_id
        )
    )

    if role is None:
        raise ValueError("Role not found in this tenant.")


    statement = (
        select(Permission)
        .join(
            RolePermission,
            RolePermission.permission_id == Permission.id
        )
        .where(
            RolePermission.role_id == role_id,
            RolePermission.tenant_id == tenant_id,
            Permission.tenant_id == tenant_id
        )
    )

    return db.scalars(statement).all()


def remove_permission_from_role(
    db: Session,
    tenant_id: UUID,
    role_id: UUID,
    permission_id: UUID
):
    assignment = db.scalar(
        select(RolePermission).where(
            RolePermission.tenant_id == tenant_id,
            RolePermission.role_id == role_id,
            RolePermission.permission_id == permission_id
        )
    )

    if assignment is None:
        return False

    db.delete(assignment)
    db.commit()

    return True