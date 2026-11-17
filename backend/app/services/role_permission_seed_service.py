from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.role import Role
from app.models.permission import Permission
from app.models.role_permission import RolePermission
from app.core.role_permission_catalog import ROLE_PERMISSION_CATALOG


def seed_role_permissions(db: Session, tenant_id: UUID):
    created_assignments = []

    for role_code, permission_keys in ROLE_PERMISSION_CATALOG.items():

        role = db.scalar(
            select(Role).where(
                Role.tenant_id == tenant_id,
                Role.code == role_code
            )
        )

        if role is None:
            continue

        for permission_key in permission_keys:

            permission = db.scalar(
                select(Permission).where(
                    Permission.tenant_id == tenant_id,
                    Permission.key == permission_key
                )
            )

            if permission is None:
                continue

            existing_assignment = db.scalar(
                select(RolePermission).where(
                    RolePermission.tenant_id == tenant_id,
                    RolePermission.role_id == role.id,
                    RolePermission.permission_id == permission.id
                )
            )

            if existing_assignment:
                continue

            assignment = RolePermission(
                tenant_id=tenant_id,
                role_id=role.id,
                permission_id=permission.id
            )

            db.add(assignment)
            created_assignments.append(assignment)

    return created_assignments