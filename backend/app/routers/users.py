
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_Db
from app.schemas.user import UserCreate, UserUpdate, UserResponse
from app.services import user_service


router = APIRouter(
    prefix="/tenants/{tenant_id}/users",
    tags=["Users"]
)


@router.post(
    "/",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED
)
def create_user(
    tenant_id: UUID,
    user_data: UserCreate,
    db: Session = Depends(get_Db)
):
    try:
        return user_service.create_user(
            db, tenant_id, user_data
        )
    except ValueError as error:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(error)
        )


@router.get("/", response_model=list[UserResponse])
def get_users(
    tenant_id: UUID,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_Db)
):
    return user_service.get_users(
        db, tenant_id, skip, limit
    )


@router.get("/{user_id}", response_model=UserResponse)
def get_user(
    tenant_id: UUID,
    user_id: UUID,
    db: Session = Depends(get_Db)
):
    user = user_service.get_user(db, tenant_id, user_id)

    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    return user


@router.patch("/{user_id}", response_model=UserResponse)
def update_user(
    tenant_id: UUID,
    user_id: UUID,
    user_data: UserUpdate,
    db: Session = Depends(get_Db)
):
    try:
        user = user_service.update_user(
            db, tenant_id, user_id, user_data
        )

        if user is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )

        return user

    except ValueError as error:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(error)
        )


@router.delete("/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_user(
    tenant_id: UUID,
    user_id: UUID,
    db: Session = Depends(get_Db)
):
    deleted = user_service.delete_user(
        db, tenant_id, user_id
    )

    if not deleted:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    return None
