from datetime import datetime

from pydantic import BaseModel, Field


class RideRequest(BaseModel):
    pickup_latitude: float = Field(..., ge=-90, le=90)
    pickup_longitude: float = Field(..., ge=-180, le=180)

    destination_latitude: float = Field(
        ...,
        ge=-90,
        le=90,
    )

    destination_longitude: float = Field(
        ...,
        ge=-180,
        le=180,
    )


class RideResponse(BaseModel):
    id: int
    passenger_id: int
    driver_id: int | None
    pickup_latitude: float
    pickup_longitude: float
    destination_latitude: float
    destination_longitude: float
    status: str
    estimated_fare: float | None
    final_fare: float | None
    requested_at: datetime
    completed_at: datetime | None

    class Config:
        from_attributes = True

class RideAcceptResponse(BaseModel):
    id: int
    passenger_id: int
    driver_id: int
    status: str

    class Config:
        from_attributes = True

class RideStatusUpdate(BaseModel):
    status: str