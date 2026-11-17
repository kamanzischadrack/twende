from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError

from app.models.user import User
from app.models.role import Role
from app.models.user_role import UserRole


def assign_role_to_user(
        db: Session,
        tenant_id: UUID,
        user_id: UUID,
        role_id: UUID,
        assigned_by: UUID | None = None
):
    user = db.scalar(
        select(User).where(
            User.id == user_id,
            User.tenant_id == tenant_id
        )
    )

    if user is None:
        raise ValueError("User not found in this tenant.")

    role = db.scalar(
        select(Role).where(
            Role.id == role_id,
            Role.tenant_id == tenant_id
        )
    )

    if role is None:
        raise ValueError("Role not found in this tenant.")

    existing_assignment = db.scalar(
        select(UserRole).where(
            UserRole.tenant_id == tenant_id,
            UserRole.user_id == user_id,
            UserRole.role_id == role_id
        )
    )

    if existing_assignment:
        raise ValueError("This role is already assigned to the user.")

    assignment = UserRole(
        tenant_id=tenant_id,
        user_id=user_id,
        role_id=role_id,
        created_by=assigned_by
    )

    try:
        db.add(assignment)
        db.commit()
        db.refresh(assignment)

    except IntegrityError:
        db.rollback()
        raise ValueError("Could not assign this role to the user.")

    return role


def get_user_roles(
        db: Session,
        tenant_id: UUID,
        user_id: UUID
):
    user = db.scalar(
        select(User).where(
            User.id == user_id,
            User.tenant_id == tenant_id
        )
    )

    if user is None:
        raise ValueError("User not found in this tenant.")

    statement = (
        select(Role)
        .join(UserRole, UserRole.role_id == Role.id)
        .where(
            UserRole.user_id == user_id,
            UserRole.tenant_id == tenant_id,
            Role.tenant_id == tenant_id
        )
    )

    return db.scalars(statement).all()


def remove_role_from_user(
        db: Session,
        tenant_id: UUID,
        user_id: UUID,
        role_id: UUID
):
    assignment = db.scalar(
        select(UserRole).where(
            UserRole.tenant_id == tenant_id,
            UserRole.user_id == user_id,
            UserRole.role_id == role_id
        )
    )

    if assignment is None:
        return False

    db.delete(assignment)
    db.commit()

    return True
