from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_Db
from app.schemas.auth import (
    LoginRequest,
    TokenResponse,
    CompanyRegistrationRequest,
    CompanyRegistrationResponse,
    RegisterAdminRequest,
    AuthSuccessResponse
)
from app.services import auth_service, company_onboarding_service

router = APIRouter(
    prefix="/auth",
    tags=["Authentication & Onboarding"]
)


@router.post("/register-company", response_model=CompanyRegistrationResponse, status_code=status.HTTP_201_CREATED)
def apply_company_registration(data: CompanyRegistrationRequest, db: Session = Depends(get_Db)):
    tenant = company_onboarding_service.submit_company_registration(db, data)
    return {
        "message": "Company registration request submitted successfully. Awaiting platform administrator approval.",
        "tenant_id": tenant.id,
        "company_name": tenant.name,
        "status": tenant.status
    }


@router.post("/register", response_model=AuthSuccessResponse, status_code=status.HTTP_201_CREATED)
def register_with_invitation(data: RegisterAdminRequest, db: Session = Depends(get_Db)):
    try:
        return company_onboarding_service.register_company_admin(db, data)
    except ValueError as err:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(err))


@router.post("/login", status_code=status.HTTP_200_OK)
def global_login(login_data: LoginRequest, db: Session = Depends(get_Db)):
    try:
        return company_onboarding_service.global_login_user(db, login_data)
    except ValueError as err:
        msg = str(err)
        status_code = status.HTTP_401_UNAUTHORIZED if "Invalid login" in msg else status.HTTP_403_FORBIDDEN
        raise HTTPException(status_code=status_code, detail=msg)


tenant_scoped_auth_router = APIRouter(
    prefix="/tenants/{tenant_id}/auth",
    tags=["Authentication"]
)


@router.post("/login", response_model=TokenResponse, status_code=status.HTTP_200_OK)
def tenant_login(tenant_id: UUID, login_data: LoginRequest, db: Session = Depends(get_Db)):
    try:
        return auth_service.login_user(db=db, tenant_id=tenant_id, login_data=login_data)
    except ValueError as error:
        message = str(error)
        status_code = status.HTTP_401_UNAUTHORIZED if message == "Invalid login credentials." else status.HTTP_403_FORBIDDEN
        raise HTTPException(status_code=status_code, detail=message)
