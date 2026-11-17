from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session

from app.core.database import get_Db
from app.schemas.vehicle_document import (
    VehicleDocumentUpdate,
    VehicleDocumentResponse
)
from app.services import document_service

router = APIRouter(
    prefix="/tenants/{tenant_id}/vehicle-documents",
    tags=["Vehicle Documents"]
)


@router.get("/expiring-alerts")
def get_expiring_documents_alert(
    tenant_id: UUID,
    days_ahead: int = Query(default=30, ge=1, le=365),
    db: Session = Depends(get_Db)
):
    return document_service.get_expiring_documents(db, tenant_id, days_ahead)


@router.get("/{document_id}", response_model=VehicleDocumentResponse)
def get_document(tenant_id: UUID, document_id: UUID, db: Session = Depends(get_Db)):
    doc = document_service.get_vehicle_document(db, tenant_id, document_id)
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found.")
    return doc


@router.put("/{document_id}", response_model=VehicleDocumentResponse)
def update_document(tenant_id: UUID, document_id: UUID, data: VehicleDocumentUpdate, db: Session = Depends(get_Db)):
    updated = document_service.update_vehicle_document(db, tenant_id, document_id, data)
    if not updated:
        raise HTTPException(status_code=404, detail="Document not found.")
    return updated


@router.delete("/{document_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_document(tenant_id: UUID, document_id: UUID, db: Session = Depends(get_Db)):
    if not document_service.delete_vehicle_document(db, tenant_id, document_id):
        raise HTTPException(status_code=404, detail="Document not found.")
