
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_Db
from app.schemas.permission import (
    PermissionCreate,
    PermissionUpdate,
    PermissionResponse
)
from app.services import permission_service


router = APIRouter(
    prefix="/tenants/{tenant_id}/permissions",
    tags=["Permissions"]
)


@router.post(
    "/",
    response_model=PermissionResponse,
    status_code=status.HTTP_201_CREATED
)
def create_permission(
    tenant_id: UUID,
    permission_data: PermissionCreate,
    db: Session = Depends(get_Db)
):
    try:
        return permission_service.create_permission(
            db, tenant_id, permission_data
        )
    except ValueError as error:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(error)
        )


@router.get("/", response_model=list[PermissionResponse])
def get_permissions(
    tenant_id: UUID,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_Db)
):
    return permission_service.get_permissions(
        db, tenant_id, skip, limit
    )


@router.get("/{permission_id}", response_model=PermissionResponse)
def get_permission(
    tenant_id: UUID,
    permission_id: UUID,
    db: Session = Depends(get_Db)
):
    permission = permission_service.get_permission(
        db, tenant_id, permission_id
    )

    if permission is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Permission not found"
        )

    return permission


@router.patch("/{permission_id}", response_model=PermissionResponse)
def update_permission(
    tenant_id: UUID,
    permission_id: UUID,
    permission_data: PermissionUpdate,
    db: Session = Depends(get_Db)
):
    try:
        permission = permission_service.update_permission(
            db, tenant_id, permission_id, permission_data
        )

        if permission is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Permission not found"
            )

        return permission

    except ValueError as error:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(error)
        )


@router.delete(
    "/{permission_id}",
    status_code=status.HTTP_204_NO_CONTENT
)
def delete_permission(
    tenant_id: UUID,
    permission_id: UUID,
    db: Session = Depends(get_Db)
):
    deleted = permission_service.delete_permission(
        db, tenant_id, permission_id
    )

    if not deleted:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Permission not found"
        )

    return None
