import uuid
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.dependencies.auth import get_current_user
from app.models.user import User
from app.core.enums import DriverStatus
from app.schemas.driver import DriverCreate, DriverUpdate, DriverResponse
from app.services.driver_service import (
    create_driver,
    list_drivers,
    update_driver,
)

router = APIRouter(prefix="/drivers", tags=["drivers"])


@router.post("", response_model=DriverResponse, status_code=status.HTTP_201_CREATED)
def register_driver(
    req: DriverCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return create_driver(
        db=db,
        tenant_id=current_user.tenant_id,
        data=req,
    )


@router.get("", response_model=list[DriverResponse])
def get_all_drivers(
    status_filter: DriverStatus | None = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return list_drivers(
        db=db,
        tenant_id=current_user.tenant_id,
        status_filter=status_filter,
    )


@router.put("/{driver_id}", response_model=DriverResponse)
def modify_driver(
    driver_id: uuid.UUID,
    req: DriverUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return update_driver(
        db=db,
        tenant_id=current_user.tenant_id,
        driver_id=driver_id,
        data=req,
    )

