from pydantic import BaseModel
from fastapi import APIRouter, Depends
from app.dependencies.auth import get_current_user
from app.models.user import User
from app.services.webhook_service import webhook_service

router = APIRouter(prefix="/webhooks", tags=["webhooks"])


class WebhookDispatchTest(BaseModel):
    event_name: str
    target_url: str
    data: dict


@router.post("/test-dispatch")
async def test_signed_webhook(
    req: WebhookDispatchTest,
    current_user: User = Depends(get_current_user),
):
    success = await webhook_service.dispatch_event(
        event_name=req.event_name,
        target_url=req.target_url,
        data=req.data,
    )
    return {
        "event_dispatched": req.event_name,
        "target_url": req.target_url,
        "success": success,
    }

