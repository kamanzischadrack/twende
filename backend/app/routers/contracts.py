import uuid
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import select

from app.core.database import get_db
from app.dependencies.auth import get_current_user
from app.models.user import User
from app.models.contract import Contract
from app.core.enums import ContractStatus
from app.schemas.contract import (
    ContractCreateFromBooking,
    HandoverRequest,
    ReturnRequest,
    ExtensionRequest,
    AddChargeRequest,
    ContractResponse,
    ContractLineResponse,
)
from app.schemas.invoice import InvoiceResponse
from app.services.contract_service import (
    create_contract_from_booking,
    execute_handover,
    add_contract_charge,
    extend_contract,
    execute_return,
)

router = APIRouter(prefix="/contracts", tags=["contracts"])
rentals_router = APIRouter(prefix="/rentals", tags=["rentals"])


@router.post("", response_model=ContractResponse, status_code=status.HTTP_201_CREATED)
def make_contract(
    req: ContractCreateFromBooking,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return create_contract_from_booking(
        db=db,
        tenant_id=current_user.tenant_id,
        data=req,
        user_id=current_user.id,
    )


@router.get("", response_model=list[ContractResponse])
def list_all_contracts(
    customer_id: uuid.UUID | None = None,
    contract_status: ContractStatus | None = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    query = select(Contract).where(Contract.tenant_id == current_user.tenant_id)
    if customer_id:
        query = query.where(Contract.customer_id == customer_id)
    if contract_status:
        query = query.where(Contract.status == contract_status)
    query = query.order_by(Contract.created_at.desc())
    return list(db.execute(query).scalars().all())


@router.get("/{contract_id}", response_model=ContractResponse)
def get_single_contract(
    contract_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    contract = db.execute(
        select(Contract).where(
            Contract.id == contract_id,
            Contract.tenant_id == current_user.tenant_id,
        )
    ).scalar_one_or_none()

    if not contract:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Contract not found")

    return contract


@router.post("/{contract_id}/handover", response_model=ContractResponse)
def handover_vehicle(
    contract_id: uuid.UUID,
    req: HandoverRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return execute_handover(
        db=db,
        tenant_id=current_user.tenant_id,
        contract_id=contract_id,
        handover_data=req,
        user_id=current_user.id,
    )


@router.post("/{contract_id}/charge", response_model=ContractLineResponse)
def add_charge(
    contract_id: uuid.UUID,
    req: AddChargeRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return add_contract_charge(
        db=db,
        tenant_id=current_user.tenant_id,
        contract_id=contract_id,
        charge_data=req,
    )


@router.post("/{contract_id}/extend", response_model=ContractResponse)
def extend_rental(
    contract_id: uuid.UUID,
    req: ExtensionRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return extend_contract(
        db=db,
        tenant_id=current_user.tenant_id,
        contract_id=contract_id,
        extension_req=req,
        user_id=current_user.id,
    )


@router.post("/{contract_id}/return", response_model=InvoiceResponse)
def return_vehicle(
    contract_id: uuid.UUID,
    req: ReturnRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return execute_return(
        db=db,
        tenant_id=current_user.tenant_id,
        contract_id=contract_id,
        return_data=req,
        user_id=current_user.id,
    )


@rentals_router.get("/active", response_model=list[ContractResponse])
def get_active_rentals(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    query = select(Contract).where(
        Contract.tenant_id == current_user.tenant_id,
        Contract.status.in_([ContractStatus.ACTIVE, ContractStatus.AMENDED]),
    ).order_by(Contract.expected_return_datetime.asc())
    return list(db.execute(query).scalars().all())

