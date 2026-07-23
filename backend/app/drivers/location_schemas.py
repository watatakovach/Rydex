from datetime import datetime

from pydantic import BaseModel, Field


class DriverLocationUpdate(BaseModel):
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)


class DriverLocationResponse(BaseModel):
    driver_id: int
    latitude: float
    longitude: float
    updated_at: datetime

    class Config:
        from_attributes = True