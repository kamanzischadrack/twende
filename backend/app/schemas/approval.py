import uuid
from datetime import datetime
from pydantic import BaseModel, ConfigDict
from app.core.enums import ApprovalDecision


class ApprovalCreateRequest(BaseModel):
    target_type: str
    target_id: uuid.UUID
    reason: str


class ApprovalDecisionRequest(BaseModel):
    decision: ApprovalDecision
    comment: str | None = None


class ApprovalResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    tenant_id: uuid.UUID
    target_type: str
    target_id: uuid.UUID
    requested_by_id: uuid.UUID
    approver_id: uuid.UUID | None
    decision: ApprovalDecision
    reason: str
    comment: str | None
    requested_at: datetime
    resolved_at: datetime | None

