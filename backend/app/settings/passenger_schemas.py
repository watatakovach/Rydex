from datetime import datetime

from pydantic import BaseModel, ConfigDict


class PassengerSettingsBase(BaseModel):
    # Registration
    passenger_registration_enabled: bool = True
    require_phone_verification: bool = True
    require_email_verification: bool = False
    allow_social_login: bool = False

    # Account Management
    allow_multiple_accounts: bool = False
    auto_suspend_after_reports: bool = False
    maximum_account_reports: int = 5

    # Ride Rules
    maximum_active_rides: int = 1
    allow_scheduled_rides: bool = True
    allow_cancel_ride: bool = True
    cancellation_limit_per_day: int = 5

    # Wallet
    wallet_enabled: bool = True
    minimum_wallet_balance: float = 0
    maximum_wallet_balance: float = 100000

    # Ratings
    allow_passenger_rating: bool = True
    require_rating_after_ride: bool = False

    # Safety
    emergency_contact_enabled: bool = True
    trip_sharing_enabled: bool = True

    # Notifications
    ride_status_notifications: bool = True
    promotional_notifications: bool = True
    payment_notifications: bool = True


class PassengerSettingsCreate(PassengerSettingsBase):
    pass


class PassengerSettingsUpdate(BaseModel):
    passenger_registration_enabled: bool | None = None
    require_phone_verification: bool | None = None
    require_email_verification: bool | None = None
    allow_social_login: bool | None = None

    allow_multiple_accounts: bool | None = None
    auto_suspend_after_reports: bool | None = None
    maximum_account_reports: int | None = None

    maximum_active_rides: int | None = None
    allow_scheduled_rides: bool | None = None
    allow_cancel_ride: bool | None = None
    cancellation_limit_per_day: int | None = None

    wallet_enabled: bool | None = None
    minimum_wallet_balance: float | None = None
    maximum_wallet_balance: float | None = None

    allow_passenger_rating: bool | None = None
    require_rating_after_ride: bool | None = None

    emergency_contact_enabled: bool | None = None
    trip_sharing_enabled: bool | None = None

    ride_status_notifications: bool | None = None
    promotional_notifications: bool | None = None
    payment_notifications: bool | None = None


class PassengerSettingsResponse(PassengerSettingsBase):
    id: int
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(
        from_attributes=True
    )