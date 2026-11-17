import uuid
from uuid import UUID
from sqlalchemy import select
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError

from app.models.tenant import Tenant
from app.models.user import User
from app.models.role import Role
from app.models.user_role import UserRole
from app.core.enums import TenantStatus, UserStatus
from app.core.security import hash_password, verify_password, create_access_token
from app.schemas.auth import (
    CompanyRegistrationRequest,
    RegisterAdminRequest,
    LoginRequest
)
from app.services.access_control_seed_service import seed_access_control


def submit_company_registration(db: Session, req: CompanyRegistrationRequest) -> Tenant:
    tenant = Tenant(
        name=req.company_name,
        country=req.country,
        currency=req.currency,
        contact_email=req.contact_email,
        contact_phone=req.contact_phone,
        tin_number=req.tin_number,
        status=TenantStatus.PENDING_APPROVAL,
        tax_settings={"vat_rate": 0.18}
    )
    db.add(tenant)
    db.commit()
    db.refresh(tenant)
    return tenant


def list_pending_companies(db: Session) -> list[Tenant]:
    stmt = select(Tenant).where(Tenant.status == TenantStatus.PENDING_APPROVAL).order_by(Tenant.created_at.desc())
    return list(db.scalars(stmt).all())


def approve_company(db: Session, tenant_id: UUID) -> tuple[Tenant, str]:
    tenant = db.get(Tenant, tenant_id)
    if not tenant:
        raise ValueError("Tenant not found.")

    tenant.status = TenantStatus.ACTIVE
    invitation_token = f"twende_inv_{uuid.uuid4().hex}"
    tenant.invitation_token = invitation_token

    seed_access_control(db, tenant.id)

    db.commit()
    db.refresh(tenant)
    return tenant, invitation_token


def register_company_admin(db: Session, req: RegisterAdminRequest) -> dict:
    tenant = db.scalar(
        select(Tenant).where(
            Tenant.invitation_token == req.invitation_token.strip(),
            Tenant.status == TenantStatus.ACTIVE
        )
    )
    if not tenant:
        raise ValueError("Invalid or expired invitation token. The company must be approved first.")

    existing_user = db.scalar(
        select(User).where(
            User.tenant_id == tenant.id,
            (User.phone == req.phone.strip()) | (User.email == req.email.strip() if req.email else False)
        )
    )
    if existing_user:
        raise ValueError("A user with this phone number or email already exists in this company.")

    admin_role = db.scalar(
        select(Role).where(
            Role.tenant_id == tenant.id,
            Role.code == "SYSTEM_ADMINISTRATOR"
        )
    )
    if not admin_role:
        raise ValueError("Company administrator role not initialized.")

    user = User(
        tenant_id=tenant.id,
        name=req.name,
        phone=req.phone.strip(),
        email=req.email.strip() if req.email else None,
        password_hash=hash_password(req.password),
        status=UserStatus.ACTIVE
    )
    db.add(user)
    db.flush()

    user_role = UserRole(
        tenant_id=tenant.id,
        user_id=user.id,
        role_id=admin_role.id
    )
    db.add(user_role)

    tenant.invitation_token = None

    db.commit()
    db.refresh(user)

    access_token = create_access_token(
        user_id=user.id,
        tenant_id=tenant.id,
        role_ids=[str(admin_role.id)]
    )

    return {
        "message": "Company administrator account registered successfully.",
        "tenant_id": tenant.id,
        "user_id": user.id,
        "name": user.name,
        "phone": user.phone,
        "email": user.email,
        "role": admin_role.name,
        "access_token": access_token,
        "token_type": "bearer"
    }


def global_login_user(db: Session, req: LoginRequest) -> dict:
    stmt = (
        select(User, Tenant)
        .join(Tenant, User.tenant_id == Tenant.id)
        .where(
            (User.phone == req.identifier.strip()) | (User.email == req.identifier.strip())
        )
    )
    match = db.execute(stmt).first()
    if not match:
        raise ValueError("Invalid login credentials.")

    user, tenant = match
    if not verify_password(req.password, user.password_hash):
        raise ValueError("Invalid login credentials.")

    if tenant.status != TenantStatus.ACTIVE:
        raise ValueError(f"Company account is {tenant.status.value.lower().replace('_', ' ')}. Please contact Twende support.")

    if user.status != UserStatus.ACTIVE:
        raise ValueError("User account is inactive or suspended.")

    role_ids = db.scalars(
        select(UserRole.role_id).where(
            UserRole.user_id == user.id,
            UserRole.tenant_id == user.tenant_id
        )
    ).all()

    access_token = create_access_token(
        user_id=user.id,
        tenant_id=user.tenant_id,
        role_ids=[str(rid) for rid in role_ids]
    )

    return {
        "access_token": access_token,
        "token_type": "bearer",
        "tenant_id": str(user.tenant_id),
        "user_id": str(user.id),
        "name": user.name
    }

