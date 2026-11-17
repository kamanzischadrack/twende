import uuid
from datetime import datetime, timezone
from sqlalchemy.orm import Session
from sqlalchemy import select
from fastapi import HTTPException, status

from app.models.approval import Approval
from app.core.enums import ApprovalDecision
from app.schemas.approval import ApprovalCreateRequest, ApprovalDecisionRequest


def request_approval(
    db: Session,
    tenant_id: uuid.UUID,
    data: ApprovalCreateRequest,
    user_id: uuid.UUID,
) -> Approval:
    approval = Approval(
        tenant_id=tenant_id,
        target_type=data.target_type,
        target_id=data.target_id,
        requested_by_id=user_id,
        decision=ApprovalDecision.PENDING,
        reason=data.reason,
    )
    db.add(approval)
    db.commit()
    db.refresh(approval)
    return approval


def decide_approval(
    db: Session,
    tenant_id: uuid.UUID,
    approval_id: uuid.UUID,
    data: ApprovalDecisionRequest,
    approver_id: uuid.UUID,
) -> Approval:
    approval = db.execute(
        select(Approval).where(
            Approval.id == approval_id,
            Approval.tenant_id == tenant_id,
        )
    ).scalar_one_or_none()

    if not approval:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Approval request not found")

    if approval.decision != ApprovalDecision.PENDING:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Approval has already been resolved as {approval.decision.value}",
        )

    approval.decision = data.decision
    approval.comment = data.comment
    approval.approver_id = approver_id
    approval.resolved_at = datetime.now(timezone.utc)

    db.commit()
    db.refresh(approval)
    return approval


def list_pending_approvals(db: Session, tenant_id: uuid.UUID) -> list[Approval]:
    return list(
        db.execute(
            select(Approval).where(
                Approval.tenant_id == tenant_id,
                Approval.decision == ApprovalDecision.PENDING,
            ).order_by(Approval.requested_at.desc())
        ).scalars().all()
    )

