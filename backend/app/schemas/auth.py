from uuid import UUID
from pydantic import BaseModel, Field
from app.core.enums import TenantStatus


class LoginRequest(BaseModel):
    identifier: str = Field(min_length=3)
    password: str = Field(min_length=8)


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class CompanyRegistrationRequest(BaseModel):
    company_name: str = Field(min_length=2, max_length=150)
    country: str = Field(default="Rwanda", max_length=200)
    currency: str = Field(default="RWF", min_length=3, max_length=3)
    contact_name: str = Field(min_length=2, max_length=150)
    contact_email: str | None = None
    contact_phone: str = Field(min_length=5, max_length=30)
    tin_number: str | None = None


class CompanyRegistrationResponse(BaseModel):
    message: str
    tenant_id: UUID
    company_name: str
    status: TenantStatus


class CompanyApprovalResponse(BaseModel):
    message: str
    tenant_id: UUID
    company_name: str
    status: TenantStatus
    invitation_token: str


class RegisterAdminRequest(BaseModel):
    invitation_token: str = Field(min_length=8)
    name: str = Field(min_length=2, max_length=150)
    phone: str = Field(min_length=5, max_length=30)
    email: str | None = None
    password: str = Field(min_length=8)


class AuthSuccessResponse(BaseModel):
    message: str
    tenant_id: UUID
    user_id: UUID
    name: str
    phone: str
    email: str | None
    role: str
    access_token: str
    token_type: str = "bearer"
