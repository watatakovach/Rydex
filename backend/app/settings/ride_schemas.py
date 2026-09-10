from datetime import datetime

from pydantic import BaseModel, ConfigDict



class RideSettingsBase(BaseModel):

    # Dispatch System

    auto_assign_driver: bool = True

    driver_matching_method: str = "nearest_driver"

    search_radius_km: float = 5.0

    maximum_search_radius_km: float = 20.0

    max_driver_results: int = 10



    # Ride Lifecycle

    ride_request_timeout_seconds: int = 60

    driver_accept_timeout_seconds: int = 30

    driver_arrival_timeout_minutes: int = 10

    allow_driver_reassignment: bool = True

    maximum_reassignments: int = 3



    # Scheduling

    scheduled_rides_enabled: bool = True

    maximum_schedule_days: int = 30



    # Cancellation

    passenger_cancel_enabled: bool = True

    driver_cancel_enabled: bool = True

    cancellation_fee_enabled: bool = False

    cancellation_fee_amount: float = 0



    # Safety

    sos_enabled: bool = True

    emergency_contact_enabled: bool = True

    share_trip_enabled: bool = True



    # Pricing

    minimum_fare: float = 150

    base_fare: float = 100

    price_per_km: float = 50

    price_per_minute: float = 5.0




class RideSettingsCreate(
    RideSettingsBase
):
    pass




class RideSettingsUpdate(BaseModel):

    auto_assign_driver: bool | None = None

    driver_matching_method: str | None = None

    search_radius_km: float | None = None

    maximum_search_radius_km: float | None = None

    max_driver_results: int | None = None


    ride_request_timeout_seconds: int | None = None

    driver_accept_timeout_seconds: int | None = None

    driver_arrival_timeout_minutes: int | None = None

    allow_driver_reassignment: bool | None = None

    maximum_reassignments: int | None = None


    scheduled_rides_enabled: bool | None = None

    maximum_schedule_days: int | None = None


    passenger_cancel_enabled: bool | None = None

    driver_cancel_enabled: bool | None = None

    cancellation_fee_enabled: bool | None = None

    cancellation_fee_amount: float | None = None


    sos_enabled: bool | None = None

    emergency_contact_enabled: bool | None = None

    share_trip_enabled: bool | None = None


    minimum_fare: float | None = None

    base_fare: float | None = None

    price_per_km: float | None = None

    price_per_minute: float | None = None




class RideSettingsResponse(
    RideSettingsBase
):

    id: int

    created_at: datetime

    updated_at: datetime


    model_config = ConfigDict(
        from_attributes=True
    )