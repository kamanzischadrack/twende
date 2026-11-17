from fastapi import FastAPI
from app.routers.auth import router as auth_router, tenant_scoped_auth_router
from app.routers.platform import router as platform_router
from app.routers.tenants import router as tenant_router
from app.routers.branches import router as branch_router
from app.routers.roles import router as role_router
from app.routers.users import router as user_router
from app.routers.permissions import router as permission_router
from app.routers.user_roles import router as user_role_router
from app.routers.role_permissions import router as role_permission_router

from app.routers.vehicle_categories import router as vehicle_category_router
from app.routers.vehicles import router as vehicle_router
from app.routers.vehicle_documents import router as vehicle_document_router
from app.routers.rate_plans import router as rate_plan_router
from app.routers.customers import router as customer_router

from app.routers.availability import router as availability_router, public_router as public_availability_router
from app.routers.bookings import router as booking_router
from app.routers.contracts import router as contract_router, rentals_router
from app.routers.payments import router as payment_router
from app.routers.invoices import router as invoice_router
from app.routers.deposits import router as deposit_router
from app.routers.maintenance import router as maintenance_router
from app.routers.drivers import router as driver_router
from app.routers.trips import router as trip_router
from app.routers.damages import router as damage_router
from app.routers.approvals import router as approval_router
from app.routers.reports import router as report_router
from app.routers.ai import router as ai_router
from app.routers.webhooks import router as webhook_router

app = FastAPI(
    title="Twende API",
    description="Car & Truck Rental Management Platform",
    version="1.0.0"
)

app.include_router(auth_router)
app.include_router(tenant_scoped_auth_router)
app.include_router(platform_router)
app.include_router(tenant_router)
app.include_router(branch_router)
app.include_router(role_router)
app.include_router(user_router)
app.include_router(permission_router)
app.include_router(user_role_router)
app.include_router(role_permission_router)

app.include_router(vehicle_category_router)
app.include_router(vehicle_router)
app.include_router(vehicle_document_router)
app.include_router(rate_plan_router)
app.include_router(customer_router)

app.include_router(availability_router)
app.include_router(public_availability_router)
app.include_router(booking_router)
app.include_router(contract_router)
app.include_router(rentals_router)
app.include_router(payment_router)
app.include_router(invoice_router)
app.include_router(deposit_router)
app.include_router(maintenance_router)
app.include_router(driver_router)
app.include_router(trip_router)
app.include_router(damage_router)
app.include_router(approval_router)
app.include_router(report_router)
app.include_router(ai_router)
app.include_router(webhook_router)


@app.get("/")
def home():
    return {
        "message": "Welcome to Twende API",
        "status": "running"
    }
