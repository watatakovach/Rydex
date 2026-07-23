from pydantic import BaseModel


class DriverVerification(BaseModel):
    is_verified: bool


class PendingDriverResponse(BaseModel):
    id: int
    user_id: int
    license_number: str
    is_verified: bool
    is_online: bool

    class Config:
        from_attributes = True