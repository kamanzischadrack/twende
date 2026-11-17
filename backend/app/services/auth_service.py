from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.user import User
from app.models.user_role import UserRole
from app.core.security import verify_password, create_access_token
from app.core.enums import UserStatus
from app.schemas.auth import LoginRequest


def login_user(
        db: Session,
        tenant_id: UUID,
        login_data: LoginRequest
):
    user = db.scalar(
        select(User).where(
            User.tenant_id == tenant_id,
            (User.phone == login_data.identifier)
            | (User.email == login_data.identifier)
        )
    )

    if user is None or not verify_password(
            login_data.password,
            user.password_hash
    ):
        raise ValueError("Invalid login credentials.")

    if user.status != UserStatus.ACTIVE:
        raise ValueError("Your account is not active.")

    role_ids = db.scalars(
        select(UserRole.role_id).where(
            UserRole.user_id == user.id,
            UserRole.tenant_id == tenant_id
        )
    ).all()

    access_token = create_access_token(
        user_id=user.id,
        tenant_id=user.tenant_id,
        role_ids=[str(role_id) for role_id in role_ids]
    )

    return {
        "access_token": access_token,
        "token_type": "bearer"
    }
