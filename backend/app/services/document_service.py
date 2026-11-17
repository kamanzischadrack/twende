from uuid import UUID
from datetime import date, timedelta
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.vehicle_document import VehicleDocument
from app.models.vehicle import Vehicle
from app.schemas.vehicle_document import VehicleDocumentCreate, VehicleDocumentUpdate


def create_vehicle_document(db: Session, tenant_id: UUID, vehicle_id: UUID, doc_data: VehicleDocumentCreate) -> VehicleDocument:
    vehicle = db.scalar(select(Vehicle).where(Vehicle.id == vehicle_id, Vehicle.tenant_id == tenant_id))
    if not vehicle:
        raise ValueError("Vehicle not found.")

    doc = VehicleDocument(**doc_data.model_dump(), tenant_id=tenant_id, vehicle_id=vehicle_id)
    db.add(doc)
    db.commit()
    db.refresh(doc)
    return doc


def get_vehicle_document(db: Session, tenant_id: UUID, document_id: UUID) -> VehicleDocument | None:
    return db.scalar(select(VehicleDocument).where(VehicleDocument.id == document_id, VehicleDocument.tenant_id == tenant_id))


def list_vehicle_documents(db: Session, tenant_id: UUID, vehicle_id: UUID) -> list[VehicleDocument]:
    stmt = select(VehicleDocument).where(
        VehicleDocument.tenant_id == tenant_id,
        VehicleDocument.vehicle_id == vehicle_id
    ).order_by(VehicleDocument.expiry_date.asc())
    return list(db.scalars(stmt).all())


def update_vehicle_document(db: Session, tenant_id: UUID, document_id: UUID, doc_data: VehicleDocumentUpdate) -> VehicleDocument | None:
    doc = get_vehicle_document(db, tenant_id, document_id)
    if not doc:
        return None

    for key, value in doc_data.model_dump(exclude_unset=True).items():
        setattr(doc, key, value)
    db.commit()
    db.refresh(doc)
    return doc


def delete_vehicle_document(db: Session, tenant_id: UUID, document_id: UUID) -> bool:
    doc = get_vehicle_document(db, tenant_id, document_id)
    if not doc:
        return False
    db.delete(doc)
    db.commit()
    return True


def get_expiring_documents(db: Session, tenant_id: UUID, days_ahead: int = 30) -> list[dict]:
    cutoff = date.today() + timedelta(days=days_ahead)
    stmt = (
        select(VehicleDocument, Vehicle)
        .join(Vehicle, VehicleDocument.vehicle_id == Vehicle.id)
        .where(VehicleDocument.tenant_id == tenant_id, VehicleDocument.expiry_date <= cutoff)
        .order_by(VehicleDocument.expiry_date.asc())
    )
    today = date.today()
    return [
        {
            "document_id": str(doc.id),
            "vehicle_id": str(veh.id),
            "plate_number": veh.plate_number,
            "vehicle": f"{veh.make} {veh.model}",
            "document_type": doc.document_type.value,
            "document_number": doc.document_number,
            "expiry_date": doc.expiry_date.isoformat(),
            "days_left": (doc.expiry_date - today).days,
            "is_critical": doc.is_critical,
            "is_expired": doc.expiry_date < today
        }
        for doc, veh in db.execute(stmt).all()
    ]


def vehicle_has_critical_expired_documents(db: Session, tenant_id: UUID, vehicle_id: UUID) -> bool:
    stmt = select(VehicleDocument).where(
        VehicleDocument.tenant_id == tenant_id,
        VehicleDocument.vehicle_id == vehicle_id,
        VehicleDocument.is_critical.is_(True),
        VehicleDocument.expiry_date < date.today()
    )
    return db.scalar(stmt) is not None
