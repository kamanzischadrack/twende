from uuid import UUID

from sqlalchemy.orm import Session

from app.services.permission_seed_service import seed_permissions
from app.services.role_seed_service import seed_default_roles
from app.services.role_permission_seed_service import seed_role_permissions


def seed_access_control(db: Session, tenant_id: UUID):
    try:

        permissions = seed_permissions(db, tenant_id)

        db.flush()

        roles = seed_default_roles(db, tenant_id)

        db.flush()

        assignments = seed_role_permissions(db, tenant_id)

        db.commit()

        return {
            "permissions_created": len(permissions),
            "roles_created": len(roles),
            "role_permissions_created": len(assignments)
        }

    except Exception:
        db.rollback()
        raise
