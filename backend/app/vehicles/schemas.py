from datetime import datetime

from pydantic import BaseModel, Field


class VehicleRegister(BaseModel):
    make: str = Field(..., min_length=2, max_length=50)
    model: str = Field(..., min_length=1, max_length=50)
    year: int = Field(..., ge=1990, le=2100)
    color: str = Field(..., min_length=2, max_length=30)
    license_plate: str = Field(..., min_length=3, max_length=20)


class VehicleResponse(BaseModel):
    id: int
    driver_id: int
    make: str
    model: str
    year: int
    color: str
    license_plate: str

    class Config:
        from_attributes = True


class VehicleImageResponse(BaseModel):
    id: int
    vehicle_id: int
    url: str
    created_at: datetime

    class Config:
        from_attributes = True


class VehicleWithImagesResponse(VehicleResponse):
    images: list[VehicleImageResponse] = []
