import hmac
import hashlib
import json
import httpx
from datetime import datetime, timezone
from app.core.config import settings


class WebhookService:
    def __init__(self):
        self.secret = settings.WEBHOOK_SIGNING_SECRET

    def generate_signature(self, payload_bytes: bytes) -> str:
        return hmac.new(
            self.secret.encode("utf-8"),
            payload_bytes,
            hashlib.sha256,
        ).hexdigest()

    async def dispatch_event(
        self,
        event_name: str,
        target_url: str,
        data: dict,
    ) -> bool:
        envelope = {
            "event": event_name,
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "data": data,
        }
        body_bytes = json.dumps(envelope).encode("utf-8")
        signature = self.generate_signature(body_bytes)

        headers = {
            "Content-Type": "application/json",
            "X-Twende-Signature": signature,
            "X-Twende-Event": event_name,
        }

        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                res = await client.post(target_url, content=body_bytes, headers=headers)
                return res.is_success
        except Exception:
            return False


webhook_service = WebhookService()

