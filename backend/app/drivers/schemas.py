from pydantic import BaseModel, Field


class DriverRegister(BaseModel):
    license_number: str = Field(min_length=3, max_length=50)


class DriverStatusUpdate(BaseModel):
    is_online: bool


class DriverLocationUpdate(BaseModel):
    latitude: float
    longitude: float


class DriverResponse(BaseModel):
    id: int
    user_id: int
    license_number: str
    vehicle_make: str | None = None
    vehicle_model: str | None = None
    vehicle_color: str | None = None
    vehicle_plate: str | None = None
    is_verified: bool
    is_online: bool
    latitude: str | None = None
    longitude: str | None = None

    model_config = {"from_attributes": True}
