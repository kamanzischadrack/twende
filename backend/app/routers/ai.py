from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.dependencies.auth import get_current_user
from app.models.user import User
from app.schemas.ai import (
    OcrScanRequest,
    OcrScanResponse,
    DamageDetectionRequest,
    DamageDetectionResponse,
    AskFleetRequest,
    AskFleetResponse,
    SmartMessageDraftRequest,
    SmartMessageDraftResponse,
)
from app.services.ai_service import ai_service

router = APIRouter(prefix="/ai", tags=["intelligent_features"])


@router.post("/ocr-scan", response_model=OcrScanResponse)
def scan_identity_document(
    req: OcrScanRequest,
    current_user: User = Depends(get_current_user),
):
    return ai_service.parse_document_ocr(req)


@router.post("/detect-damage", response_model=DamageDetectionResponse)
def compare_photos_for_damage(
    req: DamageDetectionRequest,
    current_user: User = Depends(get_current_user),
):
    return ai_service.detect_photo_damage(req)


@router.post("/ask-fleet", response_model=AskFleetResponse)
def natural_language_fleet_query(
    req: AskFleetRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return ai_service.ask_fleet_query(
        db=db,
        tenant_id=current_user.tenant_id,
        req=req,
    )


@router.post("/smart-message", response_model=SmartMessageDraftResponse)
def draft_communication(
    req: SmartMessageDraftRequest,
    current_user: User = Depends(get_current_user),
):
    return ai_service.draft_smart_message(req)

