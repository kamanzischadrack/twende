from uuid import UUID

from fastapi import Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_Db
from app.dependencies.auth import get_current_user
from app.models.user import User
from app.services.permission_service import user_has_permission


def require_permission(permission_key: str):
    def permission_checker(
            current_user: User = Depends(get_current_user),
            db: Session = Depends(get_Db)
    ):
        has_permission = user_has_permission(
            db=db,
            tenant_id=current_user.tenant_id,
            user_id=current_user.id,
            permission_key=permission_key
        )

        if not has_permission:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You do not have permission to perform this action."
            )

        return current_user

    return permission_checker
