from datetime import date, timedelta
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.dependencies.auth import get_current_user
from app.models.user import User
from app.schemas.dashboard_reports import (
    DashboardSummaryResponse,
    VehicleProfitabilityReport,
    AlertItem,
)
from app.services.report_service import (
    get_dashboard_summary,
    get_vehicle_profitability_report,
    get_system_alerts,
)

router = APIRouter(tags=["dashboard_reports_alerts"])


@router.get("/dashboard", response_model=DashboardSummaryResponse)
def get_dashboard_kpis(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return get_dashboard_summary(
        db=db,
        tenant_id=current_user.tenant_id,
    )


@router.get("/reports/profitability", response_model=VehicleProfitabilityReport)
def get_profitability_report(
    start_date: date | None = Query(None),
    end_date: date | None = Query(None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    today = date.today()
    s_date = start_date or (today - timedelta(days=30))
    e_date = end_date or today

    return get_vehicle_profitability_report(
        db=db,
        tenant_id=current_user.tenant_id,
        start_date=s_date,
        end_date=e_date,
    )


@router.get("/alerts", response_model=list[AlertItem])
def get_active_alerts(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return get_system_alerts(
        db=db,
        tenant_id=current_user.tenant_id,
    )

