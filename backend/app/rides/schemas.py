
from datetime import datetime

from pydantic import BaseModel, Field


# ============================================================
# RIDE REQUEST
# ============================================================

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


# ============================================================
# RIDE RESPONSE
# ============================================================

class RideResponse(BaseModel):
    id: int

    passenger_id: int
    driver_id: int | None = None

    pickup_latitude: float
    pickup_longitude: float

    destination_latitude: float
    destination_longitude: float

    status: str

    estimated_fare: float | None = None
    final_fare: float | None = None

    requested_at: datetime
    completed_at: datetime | None = None

    class Config:
        from_attributes = True


# ============================================================
# RIDE ACCEPT RESPONSE
# ============================================================

class RideAcceptResponse(BaseModel):
    id: int
    passenger_id: int
    driver_id: int
    status: str

    class Config:
        from_attributes = True

from datetime import datetime

from pydantic import BaseModel, Field


# ============================================================
# RIDE REQUEST
# ============================================================

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


# ============================================================
# RIDE RESPONSE
# ============================================================

class RideResponse(BaseModel):
    id: int

    passenger_id: int
    driver_id: int | None = None

    pickup_latitude: float
    pickup_longitude: float

    destination_latitude: float
    destination_longitude: float

    status: str

    estimated_fare: float | None = None
    final_fare: float | None = None

    distance_km: float | None = None
    duration_minutes: float | None = None

    requested_at: datetime
    accepted_at: datetime | None = None
    started_at: datetime | None = None
    completed_at: datetime | None = None
    cancelled_at: datetime | None = None

    cancellation_reason: str | None = None
    cancelled_by: str | None = None

    driver_rating: int | None = None
    driver_rating_comment: str | None = None
    has_driver_rating: bool = False

    class Config:
        from_attributes = True


# ============================================================
# RIDE ACCEPT RESPONSE
# ============================================================

class RideAcceptResponse(BaseModel):
    id: int
    passenger_id: int
    driver_id: int
    status: str

    class Config:
        from_attributes = True


# ============================================================
# RIDE STATUS UPDATE
# ============================================================

class RideStatusUpdate(BaseModel):
    status: str = Field(..., min_length=1, max_length=30)

    cancellation_reason: str | None = Field(
        default=None,
        max_length=255,
    )
