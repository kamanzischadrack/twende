from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_Db
from app.schemas.role import RoleResponse
from app.services import user_role_service

router = APIRouter(
    prefix="/tenants/{tenant_id}/users/{user_id}/roles",
    tags=["User Roles"]
)


@router.post(
    "/{role_id}",
    response_model=RoleResponse,
    status_code=status.HTTP_201_CREATED
)
def assign_role(
        tenant_id: UUID,
        user_id: UUID,
        role_id: UUID,
        db: Session = Depends(get_Db)
):
    try:
        return user_role_service.assign_role_to_user(
            db=db,
            tenant_id=tenant_id,
            user_id=user_id,
            role_id=role_id
        )
    except ValueError as error:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(error)
        )


@router.get("/", response_model=list[RoleResponse])
def get_user_roles(
        tenant_id: UUID,
        user_id: UUID,
        db: Session = Depends(get_Db)
):
    try:
        return user_role_service.get_user_roles(
            db=db,
            tenant_id=tenant_id,
            user_id=user_id
        )
    except ValueError as error:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(error)
        )


@router.delete(
    "/{role_id}",
    status_code=status.HTTP_204_NO_CONTENT
)
def remove_role(
        tenant_id: UUID,
        user_id: UUID,
        role_id: UUID,
        db: Session = Depends(get_Db)
):
    removed = user_role_service.remove_role_from_user(
        db=db,
        tenant_id=tenant_id,
        user_id=user_id,
        role_id=role_id
    )

    if not removed:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Role assignment not found."
        )

    return None
