from pydantic import BaseModel


class RideCreate(BaseModel):
    pickup_address: str
    destination_address: str
    pickup_latitude: float | None = None
    pickup_longitude: float | None = None
    destination_latitude: float | None = None
    destination_longitude: float | None = None


class RideStatusUpdate(BaseModel):
    status: str


class RideResponse(BaseModel):
    id: int
    passenger_id: int
    driver_id: int | None
    pickup_address: str
    destination_address: str
    fare: float
    status: str

    model_config = {"from_attributes": True}
