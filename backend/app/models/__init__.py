from app.models.tenant import Tenant
from app.models.branch import Branch
from app.models.location import Location

from app.models.user import User
from app.models.role import Role
from app.models.permission import Permission
from app.models.user_role import UserRole
from app.models.role_permission import RolePermission

from app.models.vehicle_category import VehicleCategory
from app.models.vehicle import Vehicle
from app.models.vehicle_document import VehicleDocument
from app.models.rate_plan import RatePlan

from app.models.customer import Customer
from app.models.customer_driver import CustomerDriver

from app.models.vehicle_availability import VehicleAvailabilityBlock
from app.models.booking import Booking

from app.models.contract import Contract, ContractLine, ContractAmendment
from app.models.driver import Driver, DriverAssignment
from app.models.trip import Trip, TripStop, TripCost, ProofOfDelivery
from app.models.inspection import Inspection
from app.models.damage import DamageRecord
from app.models.fuel_mileage import FuelRecord, MileageRecord
from app.models.work_order import WorkOrder
from app.models.insurance import InsurancePolicy, InsuranceClaim

from app.models.incident import Incident
from app.models.invoice import Invoice, InvoiceLine
from app.models.deposit import Deposit
from app.models.payment import Payment, PaymentAllocation
from app.models.tax_discount import TaxRate, Discount
from app.models.approval import Approval
from app.models.notification import Notification
from app.models.audit_log import AuditLog

__all__ = [
    "Tenant",
    "Branch",
    "Location",
    "User",
    "Role",
    "Permission",
    "UserRole",
    "RolePermission",
    "VehicleCategory",
    "Vehicle",
    "VehicleDocument",
    "RatePlan",
    "Customer",
    "CustomerDriver",
    "VehicleAvailabilityBlock",
    "Booking",
    "Contract",
    "ContractLine",
    "ContractAmendment",
    "Driver",
    "DriverAssignment",
    "Trip",
    "TripStop",
    "TripCost",
    "ProofOfDelivery",
    "Inspection",
    "DamageRecord",
    "FuelRecord",
    "MileageRecord",
    "WorkOrder",
    "InsurancePolicy",
    "InsuranceClaim",
    "Incident",
    "Invoice",
    "InvoiceLine",
    "Deposit",
    "Payment",
    "PaymentAllocation",
    "TaxRate",
    "Discount",
    "Approval",
    "Notification",
    "AuditLog",
]
