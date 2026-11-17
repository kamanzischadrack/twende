from app.schemas.tenant import (
    TenantCreate,
    TenantUpdate,
    TenantResponse
)

from app.schemas.branch import (
    BranchCreate,
    BranchUpdate,
    BranchResponse
)

from app.schemas.location import (
    LocationCreate,
    LocationUpdate,
    LocationResponse
)

from app.schemas.user import UserCreate, UserUpdate, UserResponse
from app.schemas.role import RoleCreate, RoleUpdate, RoleResponse
from app.schemas.permission import (
    PermissionCreate,
    PermissionUpdate,
    PermissionResponse
)

from app.schemas.vehicle_category import (
    VehicleCategoryCreate,
    VehicleCategoryUpdate,
    VehicleCategoryResponse
)
from app.schemas.vehicle import (
    VehicleCreate,
    VehicleUpdate,
    VehicleStatusOverride,
    VehicleResponse
)
from app.schemas.vehicle_document import (
    VehicleDocumentCreate,
    VehicleDocumentUpdate,
    VehicleDocumentResponse
)
from app.schemas.rate_plan import (
    RatePlanCreate,
    RatePlanUpdate,
    RatePlanResponse
)
from app.schemas.pricing import (
    PricingQuoteRequest,
    PricingQuoteResponse,
    PricingBreakdownItem
)
from app.schemas.customer import (
    CustomerCreate,
    CustomerUpdate,
    CustomerRiskUpdate,
    CustomerResponse
)
from app.schemas.customer_driver import (
    CustomerDriverCreate,
    CustomerDriverUpdate,
    CustomerDriverResponse
)
