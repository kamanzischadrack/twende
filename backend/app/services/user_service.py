from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError

from app.models.user import User
from app.models.branch import Branch
from app.core.security import hash_password
from app.schemas.user import UserCreate, UserUpdate


def create_user(
        db: Session,
        tenant_id: UUID,
        user_data: UserCreate
):
    if user_data.branch_id is not None:
        branch = db.scalar(
            select(Branch).where(
                Branch.id == user_data.branch_id,
                Branch.tenant_id == tenant_id
            )
        )

        if branch is None:
            raise ValueError("Branch not found in this tenant.")

    user_values = user_data.model_dump(exclude={"password"})

    user_values["password_hash"] = hash_password(user_data.password)

    user = User(
        **user_values,
        tenant_id=tenant_id
    )

    try:
        db.add(user)
        db.commit()
        db.refresh(user)

    except IntegrityError:
        db.rollback()
        raise ValueError(
            "A user with this phone number or email already exists in this tenant."
        )

    return user


def get_users(
    db: Session,
    tenant_id: UUID,
    skip: int = 0,
    limit: int = 100
):
    statement = (
        select(User)
        .where(User.tenant_id == tenant_id)
        .order_by(User.created_at.desc())
        .offset(skip)
        .limit(limit)
    )

    return db.scalars(statement).all()


def get_user(
    db: Session,
    tenant_id: UUID,
    user_id: UUID
):
    statement = select(User).where(
        User.id == user_id,
        User.tenant_id == tenant_id
    )

    return db.scalar(statement)


def update_user(
    db: Session,
    tenant_id: UUID,
    user_id: UUID,
    user_data: UserUpdate
):
    user = get_user(db, tenant_id, user_id)

    if user is None:
        return None

    update_data = user_data.model_dump(exclude_unset=True)

    for key, value in update_data.items():
        setattr(user, key, value)

    try:
        db.commit()
        db.refresh(user)

    except IntegrityError:
        db.rollback()
        raise ValueError(
            "A user with this phone number or email already exists."
        )

    return user


def delete_user(
    db: Session,
    tenant_id: UUID,
    user_id: UUID
):
    user = get_user(db, tenant_id, user_id)

    if user is None:
        return False

    db.delete(user)
    db.commit()

    return True
