from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_Db
from app.schemas.permission import PermissionResponse
from app.services import role_permission_service


router = APIRouter(
    prefix="/tenants/{tenant_id}/roles/{role_id}/permissions",
    tags=["Role Permissions"]
)


@router.post(
    "/{permission_id}",
    response_model=PermissionResponse,
    status_code=status.HTTP_201_CREATED
)
def assign_permission(
    tenant_id: UUID,
    role_id: UUID,
    permission_id: UUID,
    db: Session = Depends(get_Db)
):
    try:
        return role_permission_service.assign_permission_to_role(
            db=db,
            tenant_id=tenant_id,
            role_id=role_id,
            permission_id=permission_id
        )
    except ValueError as error:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(error)
        )


@router.get("/", response_model=list[PermissionResponse])
def get_role_permissions(
    tenant_id: UUID,
    role_id: UUID,
    db: Session = Depends(get_Db)
):
    try:
        return role_permission_service.get_role_permissions(
            db=db,
            tenant_id=tenant_id,
            role_id=role_id
        )
    except ValueError as error:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(error)
        )



@router.delete(
    "/{permission_id}",
    status_code=status.HTTP_204_NO_CONTENT
)
def remove_permission(
    tenant_id: UUID,
    role_id: UUID,
    permission_id: UUID,
    db: Session = Depends(get_Db)
):
    removed = role_permission_service.remove_permission_from_role(
        db=db,
        tenant_id=tenant_id,
        role_id=role_id,
        permission_id=permission_id
    )

    if not removed:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Permission assignment not found."
        )

    return None