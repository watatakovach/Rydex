from datetime import datetime

from pydantic import BaseModel, ConfigDict


class NotificationSettingsBase(BaseModel):
    # Notification Channels
    push_notifications_enabled: bool = True
    sms_notifications_enabled: bool = True
    email_notifications_enabled: bool = True
    in_app_notifications_enabled: bool = True

    # Ride Events
    ride_requested_notification: bool = True
    ride_accepted_notification: bool = True
    driver_arriving_notification: bool = True
    driver_arrived_notification: bool = True
    ride_started_notification: bool = True
    ride_completed_notification: bool = True
    ride_cancelled_notification: bool = True

    # Driver Alerts
    new_ride_request_alert: bool = True
    driver_document_expiry_alert: bool = True
    driver_payment_alert: bool = True
    driver_account_alert: bool = True

    # Passenger Alerts
    passenger_payment_alert: bool = True
    passenger_promotion_alert: bool = True
    passenger_account_alert: bool = True

    # Admin Alerts
    admin_new_driver_registration_alert: bool = True
    admin_payment_alert: bool = True
    admin_system_alert: bool = True

    # Message Settings
    sms_provider: str = "Africa's Talking"
    email_provider: str = "SMTP"
    push_provider: str = "Firebase"


class NotificationSettingsCreate(NotificationSettingsBase):
    pass


class NotificationSettingsUpdate(BaseModel):
    # Notification Channels
    push_notifications_enabled: bool | None = None
    sms_notifications_enabled: bool | None = None
    email_notifications_enabled: bool | None = None
    in_app_notifications_enabled: bool | None = None

    # Ride Events
    ride_requested_notification: bool | None = None
    ride_accepted_notification: bool | None = None
    driver_arriving_notification: bool | None = None
    driver_arrived_notification: bool | None = None
    ride_started_notification: bool | None = None
    ride_completed_notification: bool | None = None
    ride_cancelled_notification: bool | None = None

    # Driver Alerts
    new_ride_request_alert: bool | None = None
    driver_document_expiry_alert: bool | None = None
    driver_payment_alert: bool | None = None
    driver_account_alert: bool | None = None

    # Passenger Alerts
    passenger_payment_alert: bool | None = None
    passenger_promotion_alert: bool | None = None
    passenger_account_alert: bool | None = None

    # Admin Alerts
    admin_new_driver_registration_alert: bool | None = None
    admin_payment_alert: bool | None = None
    admin_system_alert: bool | None = None

    # Message Settings
    sms_provider: str | None = None
    email_provider: str | None = None
    push_provider: str | None = None


class NotificationSettingsResponse(NotificationSettingsBase):
    id: int
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(
        from_attributes=True
    )