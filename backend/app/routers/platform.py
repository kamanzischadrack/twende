from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_Db
from app.schemas.auth import CompanyApprovalResponse
from app.schemas.tenant import TenantResponse
from app.services import company_onboarding_service

router = APIRouter(
    prefix="/platform",
    tags=["Twende Platform Administration"]
)


@router.get("/companies/pending", response_model=list[TenantResponse])
def list_pending_companies(db: Session = Depends(get_Db)):
    return company_onboarding_service.list_pending_companies(db)


@router.post("/companies/{tenant_id}/approve", response_model=CompanyApprovalResponse)
def approve_company(tenant_id: UUID, db: Session = Depends(get_Db)):
    try:
        tenant, token = company_onboarding_service.approve_company(db, tenant_id)
        return {
            "message": "Company approved successfully. Share the invitation token with the company administrator to register.",
            "tenant_id": tenant.id,
            "company_name": tenant.name,
            "status": tenant.status,
            "invitation_token": token
        }
    except ValueError as err:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(err))

