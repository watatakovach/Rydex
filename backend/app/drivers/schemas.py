from pydantic import BaseModel, Field


class DriverRegister(BaseModel):
    license_number: str = Field(
        ...,
        min_length=5,
        max_length=50,
    )


class DriverResponse(BaseModel):
    id: int
    user_id: int
    license_number: str
    is_verified: bool
    is_online: bool

    class Config:
        from_attributes = True

class DriverStatusUpdate(BaseModel):
    is_online: bool