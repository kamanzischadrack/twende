from uuid import UUID
from datetime import date
from sqlalchemy import select
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError

from app.models.customer import Customer
from app.models.customer_driver import CustomerDriver
from app.core.enums import RiskStatus
from app.schemas.customer import CustomerCreate, CustomerUpdate, CustomerRiskUpdate
from app.schemas.customer_driver import CustomerDriverCreate


def create_customer(db: Session, tenant_id: UUID, customer_data: CustomerCreate) -> Customer:
    customer = Customer(**customer_data.model_dump(), tenant_id=tenant_id)
    try:
        db.add(customer)
        db.commit()
        db.refresh(customer)
        return customer
    except IntegrityError:
        db.rollback()
        raise ValueError("A customer with this phone number already exists in this company.")


def get_customer(db: Session, tenant_id: UUID, customer_id: UUID) -> Customer | None:
    return db.scalar(select(Customer).where(Customer.id == customer_id, Customer.tenant_id == tenant_id))


def list_customers(
    db: Session,
    tenant_id: UUID,
    risk_status: RiskStatus | None = None,
    search: str | None = None,
    skip: int = 0,
    limit: int = 50
) -> list[Customer]:
    query = select(Customer).where(Customer.tenant_id == tenant_id)
    if risk_status:
        query = query.where(Customer.risk_status == risk_status)
    if search:
        pattern = f"%{search.strip()}%"
        query = query.where(
            (Customer.name.ilike(pattern)) |
            (Customer.phone.ilike(pattern)) |
            (Customer.driving_licence_number.ilike(pattern))
        )
    return list(db.scalars(query.order_by(Customer.name).offset(skip).limit(limit)).all())


def update_customer(db: Session, tenant_id: UUID, customer_id: UUID, customer_data: CustomerUpdate) -> Customer | None:
    customer = get_customer(db, tenant_id, customer_id)
    if not customer:
        return None

    for key, value in customer_data.model_dump(exclude_unset=True).items():
        setattr(customer, key, value)

    try:
        db.commit()
        db.refresh(customer)
        return customer
    except IntegrityError:
        db.rollback()
        raise ValueError("Customer phone number conflict.")


def update_customer_risk_status(db: Session, tenant_id: UUID, customer_id: UUID, risk_update: CustomerRiskUpdate) -> Customer:
    customer = get_customer(db, tenant_id, customer_id)
    if not customer:
        raise ValueError("Customer not found.")

    customer.risk_status = risk_update.risk_status
    customer.risk_notes = risk_update.risk_notes
    db.commit()
    db.refresh(customer)
    return customer


def validate_customer_can_rent(db: Session, tenant_id: UUID, customer_id: UUID, estimated_cost: float = 0.0, is_credit: bool = False) -> None:
    customer = get_customer(db, tenant_id, customer_id)
    if not customer:
        raise ValueError("Customer not found.")

    if customer.risk_status == RiskStatus.BLACKLISTED:
        raise ValueError(f"Booking rejected: Customer '{customer.name}' is blacklisted.")

    if is_credit and (float(customer.outstanding_balance) + estimated_cost > float(customer.credit_limit)):
        raise ValueError("Credit limit exceeded.")


def validate_licence_validity(customer: Customer, required_class: str, end_date: date) -> None:
    if not customer.driving_licence_number:
        raise ValueError("Customer does not have a driving licence on file.")
    if not customer.licence_expiry_date or customer.licence_expiry_date < end_date:
        raise ValueError(f"Customer driving licence expires on {customer.licence_expiry_date}, before {end_date}.")
    if customer.licence_classes and required_class not in customer.licence_classes:
        raise ValueError(f"Customer licence classes do not include required class '{required_class}'.")


def create_customer_driver(db: Session, tenant_id: UUID, driver_data: CustomerDriverCreate) -> CustomerDriver:
    customer = get_customer(db, tenant_id, driver_data.customer_id)
    if not customer:
        raise ValueError("Customer not found.")

    driver = CustomerDriver(**driver_data.model_dump(), tenant_id=tenant_id)
    db.add(driver)
    db.commit()
    db.refresh(driver)
    return driver


def list_customer_drivers(db: Session, tenant_id: UUID, customer_id: UUID) -> list[CustomerDriver]:
    stmt = select(CustomerDriver).where(
        CustomerDriver.tenant_id == tenant_id,
        CustomerDriver.customer_id == customer_id
    ).order_by(CustomerDriver.full_name)
    return list(db.scalars(stmt).all())
