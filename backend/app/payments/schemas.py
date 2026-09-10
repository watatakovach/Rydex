from datetime import datetime

from pydantic import BaseModel, ConfigDict


class PaymentResponse(BaseModel):
    id: int
    ride_id: int
    passenger_id: int
    driver_id: int | None

    amount: float

    payment_method: str
    status: str

    transaction_reference: str | None

    created_at: datetime
    completed_at: datetime | None

    model_config = ConfigDict(
        from_attributes=True,
    )


class PaymentCompleteRequest(BaseModel):
    transaction_reference: str | None = None