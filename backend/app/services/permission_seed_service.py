from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.permission import Permission
from app.core.permission_catalog import PERMISSION_CATALOG


def seed_permissions(db: Session, tenant_id: UUID):
    created_permissions = []

    for key, resource, action, description in PERMISSION_CATALOG:

        existing_permission = db.scalar(
            select(Permission).where(
                Permission.tenant_id == tenant_id,
                Permission.key == key
            )
        )

        if existing_permission:
            continue

        permission = Permission(
            tenant_id=tenant_id,
            key=key,
            resource=resource,
            action=action,
            description=description
        )

        db.add(permission)
        created_permissions.append(permission)

    return created_permissions