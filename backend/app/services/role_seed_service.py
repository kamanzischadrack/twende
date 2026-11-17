from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.role import Role
from app.core.enums import RoleDevice


DEFAULT_ROLES = [
    (
        "SYSTEM_ADMINISTRATOR",
        "System Administrator",
        "Configure company, branches, users, roles, rates, taxes and policies",
        RoleDevice.LAPTOP
    ),
    (
        "OWNER_MANAGEMENT",
        "Owner / Management",
        "View revenue, profit, utilization, debts and business risks",
        RoleDevice.PHONE_LAPTOP
    ),
    (
        "RENTAL_MANAGER",
        "Rental Manager",
        "Manage bookings, contracts, approvals and branch operations",
        RoleDevice.LAPTOP
    ),
    (
        "RENTAL_OFFICER",
        "Rental Officer",
        "Register customers, book, hand over and receive vehicles",
        RoleDevice.PHONE_LAPTOP
    ),
    (
        "FLEET_MANAGER",
        "Fleet Manager",
        "Manage vehicles, maintenance and fleet availability",
        RoleDevice.LAPTOP
    ),
    (
        "FINANCE_OFFICER",
        "Finance Officer",
        "Manage invoices, payments, deposits and financial reports",
        RoleDevice.LAPTOP
    ),
    (
        "DRIVER_CHAUFFEUR",
        "Driver / Chauffeur",
        "View assigned rentals and trips and report incidents",
        RoleDevice.PHONE
    ),
    (
        "CUSTOMER",
        "Customer",
        "Book vehicles, sign contracts, make payments and view documents",
        RoleDevice.PHONE
    ),
]


def seed_default_roles(db: Session, tenant_id: UUID):
    created_roles = []

    for code, name, description, primary_device in DEFAULT_ROLES:

        existing_role = db.scalar(
            select(Role).where(
                Role.tenant_id == tenant_id,
                Role.code == code
            )
        )

        if existing_role:
            continue

        role = Role(
            tenant_id=tenant_id,
            code=code,
            name=name,
            description=description,
            primary_device=primary_device
        )

        db.add(role)
        created_roles.append(role)

    return created_roles