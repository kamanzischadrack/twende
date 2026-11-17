import math
from uuid import UUID
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.rate_plan import RatePlan
from app.models.tenant import Tenant
from app.schemas.rate_plan import RatePlanCreate, RatePlanUpdate
from app.schemas.pricing import (
    PricingQuoteRequest,
    PricingQuoteResponse,
    PricingBreakdownItem
)


def create_rate_plan(db: Session, tenant_id: UUID, plan_data: RatePlanCreate) -> RatePlan:
    plan = RatePlan(**plan_data.model_dump(), tenant_id=tenant_id)
    db.add(plan)
    db.commit()
    db.refresh(plan)
    return plan


def get_rate_plan(db: Session, tenant_id: UUID, plan_id: UUID) -> RatePlan | None:
    return db.scalar(select(RatePlan).where(RatePlan.id == plan_id, RatePlan.tenant_id == tenant_id))


def list_rate_plans(
    db: Session,
    tenant_id: UUID,
    category_id: UUID | None = None,
    vehicle_id: UUID | None = None,
    active_only: bool = True
) -> list[RatePlan]:
    query = select(RatePlan).where(RatePlan.tenant_id == tenant_id)
    if active_only:
        query = query.where(RatePlan.is_active.is_(True))
    if category_id:
        query = query.where(RatePlan.category_id == category_id)
    if vehicle_id:
        query = query.where(RatePlan.vehicle_id == vehicle_id)
    return list(db.scalars(query).all())


def update_rate_plan(db: Session, tenant_id: UUID, plan_id: UUID, plan_data: RatePlanUpdate) -> RatePlan | None:
    plan = get_rate_plan(db, tenant_id, plan_id)
    if not plan:
        return None
    for key, value in plan_data.model_dump(exclude_unset=True).items():
        setattr(plan, key, value)
    db.commit()
    db.refresh(plan)
    return plan


def get_applicable_rate_plan(
    db: Session,
    tenant_id: UUID,
    category_id: UUID,
    vehicle_id: UUID | None = None,
    specific_plan_id: UUID | None = None
) -> RatePlan | None:
    if specific_plan_id:
        return get_rate_plan(db, tenant_id, specific_plan_id)
    if vehicle_id:
        v_plan = db.scalar(select(RatePlan).where(RatePlan.tenant_id == tenant_id, RatePlan.vehicle_id == vehicle_id, RatePlan.is_active.is_(True)))
        if v_plan:
            return v_plan
    return db.scalar(select(RatePlan).where(RatePlan.tenant_id == tenant_id, RatePlan.category_id == category_id, RatePlan.vehicle_id.is_(None), RatePlan.is_active.is_(True)))


def calculate_quote(db: Session, tenant_id: UUID, quote_req: PricingQuoteRequest) -> PricingQuoteResponse:
    if quote_req.end_datetime <= quote_req.start_datetime:
        raise ValueError("Return date and time must be strictly after pickup date and time (BR05).")

    plan = get_applicable_rate_plan(db, tenant_id, quote_req.category_id, quote_req.vehicle_id, quote_req.rate_plan_id)
    if not plan:
        raise ValueError("No active rate plan found for the requested category or vehicle.")

    tenant = db.get(Tenant, tenant_id)
    vat_rate = float(tenant.tax_settings.get("vat_rate", 0.18)) if tenant and tenant.tax_settings else 0.18

    total_seconds = (quote_req.end_datetime - quote_req.start_datetime).total_seconds()
    full_days = int(total_seconds // 86400)
    rem_hours = (total_seconds % 86400) / 3600.0

    grace_hours = plan.grace_period_minutes / 60.0
    effective_hours = 0 if rem_hours <= grace_hours else int(math.ceil(rem_hours))

    breakdown: list[PricingBreakdownItem] = []
    total_rental = 0.0

    months = full_days // 30
    days_rem = full_days % 30

    if months > 0:
        cost = months * float(plan.monthly_rate)
        total_rental += cost
        breakdown.append(PricingBreakdownItem(unit_type="month", units=months, unit_rate=float(plan.monthly_rate), subtotal=cost))

    weeks = days_rem // 7
    days = days_rem % 7

    day_uncapped = days * float(plan.daily_rate)
    day_capped = day_uncapped >= float(plan.weekly_rate) and days > 0
    day_cost = float(plan.weekly_rate) if day_capped else day_uncapped

    rem_cost = (weeks * float(plan.weekly_rate)) + day_cost

    if rem_cost >= float(plan.monthly_rate) and days_rem > 0:
        total_rental += float(plan.monthly_rate)
        breakdown.append(PricingBreakdownItem(
            unit_type="month", units=1, unit_rate=float(plan.monthly_rate), subtotal=float(plan.monthly_rate),
            applied_capping=True, capping_description=f"{days_rem} days capped at 1 monthly rate"
        ))
    else:
        if weeks > 0:
            w_cost = weeks * float(plan.weekly_rate)
            total_rental += w_cost
            breakdown.append(PricingBreakdownItem(unit_type="week", units=weeks, unit_rate=float(plan.weekly_rate), subtotal=w_cost))
        if days > 0:
            total_rental += day_cost
            breakdown.append(PricingBreakdownItem(
                unit_type="day", units=days, unit_rate=float(plan.daily_rate), subtotal=day_cost,
                applied_capping=day_capped, capping_description="Capped at weekly rate" if day_capped else None
            ))

    if effective_hours > 0:
        h_rate = float(plan.hourly_rate) if plan.hourly_rate else float(plan.daily_rate) / 8.0
        h_uncapped = effective_hours * h_rate
        h_capped = h_uncapped >= float(plan.daily_rate)
        h_cost = float(plan.daily_rate) if h_capped else h_uncapped
        total_rental += h_cost
        breakdown.append(PricingBreakdownItem(
            unit_type="hour", units=effective_hours, unit_rate=h_rate, subtotal=h_cost,
            applied_capping=h_capped, capping_description="Capped at daily rate" if h_capped else None
        ))

    if total_rental == 0.0:
        total_rental = float(plan.daily_rate)
        breakdown.append(PricingBreakdownItem(unit_type="day", units=1, unit_rate=float(plan.daily_rate), subtotal=float(plan.daily_rate)))

    discount_amount = total_rental * (float(quote_req.discount_pct) / 100.0)
    net_rental = total_rental - discount_amount
    tax_amount = net_rental * vat_rate
    billable_days = max(1, full_days + (1 if effective_hours > 0 else 0))

    return PricingQuoteResponse(
        category_id=plan.category_id,
        vehicle_id=plan.vehicle_id,
        rate_plan_id=plan.id,
        currency=plan.currency,
        duration_days=full_days,
        duration_hours=effective_hours,
        breakdown=breakdown,
        rental_charge=round(total_rental, 2),
        discount_pct=round(quote_req.discount_pct, 2),
        discount_amount=round(discount_amount, 2),
        net_rental_charge=round(net_rental, 2),
        tax_rate=round(vat_rate, 4),
        tax_amount=round(tax_amount, 2),
        total_quote=round(net_rental + tax_amount, 2),
        required_deposit=float(plan.default_deposit_amount),
        included_km_total=billable_days * plan.included_km_per_day,
        excess_km_rate=float(plan.excess_km_rate)
    )


def calculate_rental_charge(
    duration_hours: float,
    hourly_rate: float | None,
    daily_rate: float,
    weekly_rate: float | None = None,
    monthly_rate: float | None = None,
    grace_period_mins: int = 60,
) -> float:
    full_days = int(duration_hours // 24)
    rem_hours = duration_hours % 24
    if rem_hours <= (grace_period_mins / 60.0):
        effective_hours = 0
    else:
        effective_hours = int(math.ceil(rem_hours))

    w_rate = weekly_rate or (daily_rate * 6)
    m_rate = monthly_rate or (w_rate * 3)

    months = full_days // 30
    days_rem = full_days % 30

    total = months * m_rate

    weeks = days_rem // 7
    days = days_rem % 7

    day_uncapped = days * daily_rate
    day_cost = w_rate if day_uncapped >= w_rate and days > 0 else day_uncapped
    rem_cost = (weeks * w_rate) + day_cost

    if rem_cost >= m_rate and days_rem > 0:
        total += m_rate
    else:
        total += rem_cost

    if effective_hours > 0:
        h_rate = hourly_rate or (daily_rate / 8.0)
        h_uncapped = effective_hours * h_rate
        total += daily_rate if h_uncapped >= daily_rate else h_uncapped

    if total == 0.0:
        total = daily_rate

    return total

