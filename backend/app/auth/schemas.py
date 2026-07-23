from pydantic import BaseModel, EmailStr, Field


class UserRegister(BaseModel):
    full_name: str = Field(..., min_length=2, max_length=100)
    phone_number: str = Field(..., min_length=7, max_length=20)
    email: EmailStr | None = None
    password: str = Field(..., min_length=8, max_length=128)


class UserResponse(BaseModel):
    id: int
    full_name: str
    phone_number: str
    email: str | None = None
    role: str
    is_active: bool

    class Config:
        from_attributes = True

class UserLogin(BaseModel):
    phone_number: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"