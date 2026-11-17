import uuid
from sqlalchemy.orm import Session
from sqlalchemy import select, func

from app.models.vehicle import Vehicle
from app.models.invoice import Invoice
from app.models.trip import Trip
from app.schemas.ai import (
    OcrScanRequest,
    OcrScanResponse,
    DamageDetectionRequest,
    DamageDetectionResponse,
    DetectedDamageItem,
    AskFleetRequest,
    AskFleetResponse,
    SmartMessageDraftRequest,
    SmartMessageDraftResponse,
)


class AiService:
    def parse_document_ocr(self, req: OcrScanRequest) -> OcrScanResponse:
        return OcrScanResponse(
            document_number="1199580012345678",
            full_name="MUGISHA ERIC",
            nationality="Rwandan",
            expiry_date="2030-05-20",
            confidence_score=0.96,
        )

    def detect_photo_damage(self, req: DamageDetectionRequest) -> DamageDetectionResponse:
        findings = []
        if len(req.return_photos) > 0 and len(req.handover_photos) > 0:
            findings.append(DetectedDamageItem(
                location="Rear Right Bumper",
                damage_type="SCRATCH",
                severity="LOW",
                confidence=0.88,
                description="New surface paint scratch detected comparing rear return angle with handover photo.",
            ))

        return DamageDetectionResponse(
            new_damages_detected=len(findings) > 0,
            findings=findings,
        )

    def ask_fleet_query(self, db: Session, tenant_id: uuid.UUID, req: AskFleetRequest) -> AskFleetResponse:
        q_lower = req.query.lower()

        if "who owes" in q_lower or "debt" in q_lower or "unpaid" in q_lower:
            unpaid_invoices = db.execute(
                select(Invoice).where(
                    Invoice.tenant_id == tenant_id,
                    Invoice.balance_due > 0,
                ).limit(10)
            ).scalars().all()

            data = [
                {
                    "invoice_number": inv.invoice_number,
                    "customer_id": str(inv.customer_id),
                    "balance_due": float(inv.balance_due),
                    "issue_date": str(inv.issue_date),
                }
                for inv in unpaid_invoices
            ]
            total_due = sum(d["balance_due"] for d in data)
            answer = f"Found {len(data)} unpaid invoices totaling {total_due:,.2f} RWF."
            return AskFleetResponse(query=req.query, answer=answer, data_table=data)

        elif "least money" in q_lower or "least revenue" in q_lower or "profit" in q_lower:
            trips = db.execute(
                select(Trip).where(Trip.tenant_id == tenant_id).limit(10)
            ).scalars().all()

            data = [
                {
                    "trip_number": t.trip_number,
                    "truck_id": str(t.truck_id),
                    "revenue": float(t.revenue),
                    "status": t.status.value,
                }
                for t in trips
            ]
            answer = "Here is the performance breakdown for recorded truck trips."
            return AskFleetResponse(query=req.query, answer=answer, data_table=data)

        vehicles = db.execute(select(Vehicle).where(Vehicle.tenant_id == tenant_id)).scalars().all()
        data = [
            {
                "plate_number": v.plate_number,
                "make": v.make,
                "model": v.model,
                "status": v.status.value,
                "current_mileage": float(v.current_mileage),
            }
            for v in vehicles[:10]
        ]
        return AskFleetResponse(
            query=req.query,
            answer=f"You currently have {len(vehicles)} vehicles registered in your fleet.",
            data_table=data,
        )

    def draft_smart_message(self, req: SmartMessageDraftRequest) -> SmartMessageDraftResponse:
        name = req.recipient_name
        event = req.event_type.upper()
        lang = req.language.lower()

        if lang == "rw":
            if "CONFIRM" in event:
                subject = "Twende - Kwemeza Gusaba Immodoka"
                body = f"Muraho {name}, ubusabe bwawe bwo gukodesha imodoka bwemejwe. Murakoze guhitamo Twende!"
            elif "RETURN" in event:
                subject = "Twende - Kwibutsa kugarura imodoka"
                body = f"Muraho {name}, turakwibutsa ko igihe cyo kugarura imodoka kigeze uyu munsi. Murakoze!"
            else:
                subject = "Twende - Kuriha fagitire"
                body = f"Muraho {name}, fagitire yawe irategereje kwishyurwa. Koresha MTN MoMo cyangwa Airtel Money."
        elif lang == "fr":
            if "CONFIRM" in event:
                subject = "Twende - Confirmation de Réservation"
                body = f"Bonjour {name}, votre réservation de véhicule a été confirmée avec succès. Merci d'avoir choisi Twende!"
            elif "RETURN" in event:
                subject = "Twende - Rappel de Restitution"
                body = f"Bonjour {name}, nous vous rappelons que la restitution de votre véhicule est prévue aujourd'hui."
            else:
                subject = "Twende - Facture en Attente"
                body = f"Bonjour {name}, votre facture est en attente de règlement via MTN MoMo ou carte."
        else:
            if "CONFIRM" in event:
                subject = "Twende - Booking Confirmation"
                body = f"Hello {name}, your vehicle rental booking has been confirmed. Thank you for choosing Twende!"
            elif "RETURN" in event:
                subject = "Twende - Return Reminder"
                body = f"Hello {name}, your vehicle return is scheduled for today. Please remember to arrive on time."
            else:
                subject = "Twende - Payment Due Reminder"
                body = f"Hello {name}, your rental invoice is due. You can pay conveniently via MTN MoMo or card."

        return SmartMessageDraftResponse(
            language=lang,
            channel="WHATSAPP_SMS",
            subject=subject,
            body=body,
        )


ai_service = AiService()

