from uuid import UUID

from fastapi import Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.database import get_Db
from app.dependencies.auth import get_current_user
from app.models.user import User
from app.models.branch import Branch
from app.services.permission_service import user_has_permission


def require_branch_access(
    branch_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_Db)
):

    branch = db.scalar(
        select(Branch).where(
            Branch.id == branch_id,
            Branch.tenant_id == current_user.tenant_id
        )
    )

    if branch is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Branch not found."
        )


    if current_user.branch_id == branch_id:
        return current_user


    has_global_access = user_has_permission(
        db=db,
        tenant_id=current_user.tenant_id,
        user_id=current_user.id,
        permission_key="branch.access_all"
    )

    if not has_global_access:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You do not have access to this branch."
        )

    return current_user