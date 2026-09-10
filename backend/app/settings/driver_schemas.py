from datetime import datetime
from pydantic import BaseModel, ConfigDict


class DriverSettingsBase(BaseModel):

    driver_registration_enabled: bool = True

    auto_approve_driver: bool = False

    require_admin_verification: bool = True


    require_driving_license: bool = True

    require_vehicle_documents: bool = True

    require_profile_photo: bool = True
    
    require_national_id: bool = True
    
    require_vehicle_verification: bool = True


    document_expiry_check: bool = True


    allow_driver_online: bool = True

    require_location_tracking: bool = True

    offline_timeout_minutes: int = 15


    minimum_driver_rating: float = 3.5

    rating_warning_threshold: float = 3.0

    suspend_low_rating_driver: bool = False


    

    minimum_driver_balance: float = 0


    maximum_active_rides: int = 1

    allow_multiple_vehicle: bool = False
    
    notify_new_ride_requests: bool = True
    notify_payment_updates: bool = True
    notify_document_expiry: bool = True



class DriverSettingsCreate(DriverSettingsBase):
    pass



class DriverSettingsUpdate(BaseModel):

    driver_registration_enabled: bool | None = None
    auto_approve_driver: bool | None = None
    require_admin_verification: bool | None = None

    require_driving_license: bool | None = None
    require_vehicle_documents: bool | None = None
    require_profile_photo: bool | None = None
    require_national_id: bool | None = None
    require_vehicle_verification: bool | None = None

    document_expiry_check: bool | None = None

    allow_driver_online: bool | None = None
    require_location_tracking: bool | None = None
    offline_timeout_minutes: int | None = None

    minimum_driver_rating: float | None = None
    rating_warning_threshold: float | None = None
    suspend_low_rating_driver: bool | None = None

   

    maximum_active_rides: int | None = None
    allow_multiple_vehicle: bool | None = None
    
    notify_new_ride_requests: bool | None = None
    notify_payment_updates: bool | None = None
    notify_document_expiry: bool | None = None



class DriverSettingsResponse(
    DriverSettingsBase
):

    id: int
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(
        from_attributes=True
    )