from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_Db
from app.schemas.branch import BranchCreate, BranchUpdate, BranchResponse
from app.services import branch_service

router = APIRouter(
    prefix="/tenants/{tenant_id}/branches",
    tags=["Branches"]
)


@router.post("", response_model=BranchResponse, status_code=status.HTTP_201_CREATED)
def create_branch(tenant_id: UUID, data: BranchCreate, db: Session = Depends(get_Db)):
    return branch_service.create_branch(db, tenant_id, data)


@router.get("", response_model=list[BranchResponse])
def list_branches(tenant_id: UUID, skip: int = 0, limit: int = 50, db: Session = Depends(get_Db)):
    return branch_service.list_branches(db, tenant_id, skip, limit)


@router.get("/{branch_id}", response_model=BranchResponse)
def get_branch(tenant_id: UUID, branch_id: UUID, db: Session = Depends(get_Db)):
    branch = branch_service.get_branch(db, tenant_id, branch_id)
    if not branch:
        raise HTTPException(status_code=404, detail="Branch not found.")
    return branch


@router.put("/{branch_id}", response_model=BranchResponse)
def update_branch(tenant_id: UUID, branch_id: UUID, data: BranchUpdate, db: Session = Depends(get_Db)):
    updated = branch_service.update_branch(db, tenant_id, branch_id, data)
    if not updated:
        raise HTTPException(status_code=404, detail="Branch not found.")
    return updated


@router.delete("/{branch_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_branch(tenant_id: UUID, branch_id: UUID, db: Session = Depends(get_Db)):
    if not branch_service.delete_branch(db, tenant_id, branch_id):
        raise HTTPException(status_code=404, detail="Branch not found.")
