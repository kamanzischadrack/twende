from uuid import UUID
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.branch import Branch
from app.schemas.branch import BranchCreate, BranchUpdate


def create_branch(db: Session, tenant_id: UUID, data: BranchCreate) -> Branch:
    branch = Branch(**data.model_dump(), tenant_id=tenant_id)
    db.add(branch)
    db.commit()
    db.refresh(branch)
    return branch


def get_branch(db: Session, tenant_id: UUID, branch_id: UUID) -> Branch | None:
    return db.scalar(select(Branch).where(Branch.id == branch_id, Branch.tenant_id == tenant_id))


def list_branches(db: Session, tenant_id: UUID, skip: int = 0, limit: int = 50) -> list[Branch]:
    stmt = select(Branch).where(Branch.tenant_id == tenant_id).order_by(Branch.name).offset(skip).limit(limit)
    return list(db.scalars(stmt).all())


def update_branch(db: Session, tenant_id: UUID, branch_id: UUID, data: BranchUpdate) -> Branch | None:
    branch = get_branch(db, tenant_id, branch_id)
    if not branch:
        return None
    for key, value in data.model_dump(exclude_unset=True).items():
        setattr(branch, key, value)
    db.commit()
    db.refresh(branch)
    return branch


def delete_branch(db: Session, tenant_id: UUID, branch_id: UUID) -> bool:
    branch = get_branch(db, tenant_id, branch_id)
    if not branch:
        return False
    db.delete(branch)
    db.commit()
    return True
