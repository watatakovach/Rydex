from pydantic import BaseModel, Field


class DriverRegister(BaseModel):
    license_number: str = Field(
        ...,
        min_length=5,
        max_length=50,
    )


class DriverStatusUpdate(BaseModel):
    is_online: bool


class DriverUpdate(BaseModel):
    vehicle_make: str | None = None
    vehicle_model: str | None = None
    vehicle_color: str | None = None
    vehicle_plate: str | None = None


class DriverResponse(BaseModel):
    id: int
    user_id: int

    license_number: str

    vehicle_make: str | None = None
    vehicle_model: str | None = None
    vehicle_color: str | None = None
    vehicle_plate: str | None = None

    profile_photo: str | None = None
    vehicle_photo: str | None = None

    driving_license_document: str | None = None
    national_id_document: str | None = None
    vehicle_document: str | None = None

    is_verified: bool
    is_online: bool

    average_rating: float | None = None
    rating_count: int = 0

    class Config:
        from_attributes = True

class DriverProfileResponse(BaseModel):
    id: int
    user_id: int

    full_name: str
    phone_number: str
    email: str | None = None

    license_number: str

    vehicle_make: str | None = None
    vehicle_model: str | None = None
    vehicle_color: str | None = None
    vehicle_plate: str | None = None

    profile_photo: str | None = None
    vehicle_photo: str | None = None

    driving_license_document: str | None = None
    national_id_document: str | None = None
    vehicle_document: str | None = None

    is_verified: bool
    is_online: bool

    average_rating: float | None = None
    rating_count: int = 0

    class Config:
        from_attributes = True
