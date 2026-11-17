from pydantic import BaseModel


class OcrScanRequest(BaseModel):
    image_url: str
    document_type: str = "NATIONAL_ID"


class OcrScanResponse(BaseModel):
    document_number: str
    full_name: str
    nationality: str
    expiry_date: str | None = None
    confidence_score: float = 0.95


class DamageDetectionRequest(BaseModel):
    handover_photos: list[str]
    return_photos: list[str]


class DetectedDamageItem(BaseModel):
    location: str
    damage_type: str
    severity: str
    confidence: float
    description: str


class DamageDetectionResponse(BaseModel):
    new_damages_detected: bool
    findings: list[DetectedDamageItem]


class AskFleetRequest(BaseModel):
    query: str


class AskFleetResponse(BaseModel):
    query: str
    answer: str
    data_table: list[dict] = []


class SmartMessageDraftRequest(BaseModel):
    event_type: str
    language: str = "en"
    recipient_name: str
    details: dict


class SmartMessageDraftResponse(BaseModel):
    language: str
    channel: str
    subject: str
    body: str

