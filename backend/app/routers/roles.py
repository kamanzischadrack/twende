from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_Db
from app.schemas.role import RoleCreate, RoleUpdate, RoleResponse
from app.services import role_service

router = APIRouter(
    prefix="/tenants/{tenant_id}/roles",
    tags=["Roles"]
)


@router.post(
    "/",
    response_model=RoleResponse,
    status_code=status.HTTP_201_CREATED
)
def create_role(
        tenant_id: UUID,
        role_data: RoleCreate,
        db: Session = Depends(get_Db)
):
    try:
        return role_service.create_role(db, tenant_id, role_data)
    except ValueError as error:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(error)
        )


@router.get("/", response_model=list[RoleResponse])
def get_roles(
        tenant_id: UUID,
        skip: int = 0,
        limit: int = 100,
        db: Session = Depends(get_Db)
):
    return role_service.get_roles(db, tenant_id, skip, limit)


@router.get("/{role_id}", response_model=RoleResponse)
def get_role(
        tenant_id: UUID,
        role_id: UUID,
        db: Session = Depends(get_Db)
):
    role = role_service.get_role(db, tenant_id, role_id)

    if role is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Role not found"
        )

    return role


@router.patch("/{role_id}", response_model=RoleResponse)
def update_role(
        tenant_id: UUID,
        role_id: UUID,
        role_data: RoleUpdate,
        db: Session = Depends(get_Db)
):
    try:
        role = role_service.update_role(
            db, tenant_id, role_id, role_data
        )

        if role is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Role not found"
            )

        return role

    except ValueError as error:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(error)
        )


@router.delete(
    "/{role_id}",
    status_code=status.HTTP_204_NO_CONTENT
)
def delete_role(
        tenant_id: UUID,
        role_id: UUID,
        db: Session = Depends(get_Db)
):
    deleted = role_service.delete_role(db, tenant_id, role_id)

    if not deleted:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Role not found"
        )

    return None
