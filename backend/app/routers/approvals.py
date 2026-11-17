import uuid
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.dependencies.auth import get_current_user
from app.models.user import User
from app.schemas.approval import (
    ApprovalCreateRequest,
    ApprovalDecisionRequest,
    ApprovalResponse,
)
from app.services.approval_service import (
    request_approval,
    decide_approval,
    list_pending_approvals,
)

router = APIRouter(prefix="/approvals", tags=["approvals"])


@router.post("", response_model=ApprovalResponse, status_code=status.HTTP_201_CREATED)
def submit_approval_request(
    req: ApprovalCreateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return request_approval(
        db=db,
        tenant_id=current_user.tenant_id,
        data=req,
        user_id=current_user.id,
    )


@router.get("/pending", response_model=list[ApprovalResponse])
def get_pending_approvals(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return list_pending_approvals(
        db=db,
        tenant_id=current_user.tenant_id,
    )


@router.post("/{approval_id}/decide", response_model=ApprovalResponse)
def resolve_approval(
    approval_id: uuid.UUID,
    req: ApprovalDecisionRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return decide_approval(
        db=db,
        tenant_id=current_user.tenant_id,
        approval_id=approval_id,
        data=req,
        approver_id=current_user.id,
    )

