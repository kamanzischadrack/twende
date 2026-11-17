import uuid
from sqlalchemy.orm import Session
from sqlalchemy import select
from app.models.audit_log import AuditLog
from app.core.enums import AuditAction


def log_audit(
    db: Session,
    tenant_id: uuid.UUID,
    action: AuditAction,
    entity_name: str,
    entity_id: uuid.UUID | None = None,
    user_id: uuid.UUID | None = None,
    before_state: dict | None = None,
    after_state: dict | None = None,
    ip_address: str | None = None,
    device: str | None = None,
) -> AuditLog:
    entry = AuditLog(
        tenant_id=tenant_id,
        user_id=user_id,
        action=action,
        entity_name=entity_name,
        entity_id=entity_id,
        before_state=before_state,
        after_state=after_state,
        ip_address=ip_address,
        device=device,
    )
    db.add(entry)
    db.commit()
    db.refresh(entry)
    return entry


def query_audit_logs(
    db: Session,
    tenant_id: uuid.UUID,
    entity_name: str | None = None,
    user_id: uuid.UUID | None = None,
    limit: int = 100,
) -> list[AuditLog]:
    query = select(AuditLog).where(AuditLog.tenant_id == tenant_id)
    if entity_name:
        query = query.where(AuditLog.entity_name == entity_name)
    if user_id:
        query = query.where(AuditLog.user_id == user_id)
    query = query.order_by(AuditLog.created_at.desc()).limit(limit)
    return list(db.execute(query).scalars().all())

