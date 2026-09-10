from sqlalchemy import (
    Column,
    Integer,
    String,
    Boolean,
    DateTime,
    func,
)

from app.database.database import Base



class NotificationSettings(Base):

    __tablename__ = "notification_settings"


    id = Column(
        Integer,
        primary_key=True,
        index=True
    )


    # Notification Channels

    push_notifications_enabled = Column(
        Boolean,
        default=True
    )


    sms_notifications_enabled = Column(
        Boolean,
        default=True
    )


    email_notifications_enabled = Column(
        Boolean,
        default=True
    )


    in_app_notifications_enabled = Column(
        Boolean,
        default=True
    )


    # Ride Events

    ride_requested_notification = Column(
        Boolean,
        default=True
    )


    ride_accepted_notification = Column(
        Boolean,
        default=True
    )


    driver_arriving_notification = Column(
        Boolean,
        default=True
    )


    driver_arrived_notification = Column(
        Boolean,
        default=True
    )


    ride_started_notification = Column(
        Boolean,
        default=True
    )


    ride_completed_notification = Column(
        Boolean,
        default=True
    )


    ride_cancelled_notification = Column(
        Boolean,
        default=True
    )


    # Driver Alerts

    new_ride_request_alert = Column(
        Boolean,
        default=True
    )


    driver_document_expiry_alert = Column(
        Boolean,
        default=True
    )


    driver_payment_alert = Column(
        Boolean,
        default=True
    )


    driver_account_alert = Column(
        Boolean,
        default=True
    )


    # Passenger Alerts

    passenger_payment_alert = Column(
        Boolean,
        default=True
    )


    passenger_promotion_alert = Column(
        Boolean,
        default=True
    )


    passenger_account_alert = Column(
        Boolean,
        default=True
    )


    # Admin Alerts

    admin_new_driver_registration_alert = Column(
        Boolean,
        default=True
    )


    admin_payment_alert = Column(
        Boolean,
        default=True
    )


    admin_system_alert = Column(
        Boolean,
        default=True
    )


    # Message Settings

    sms_provider = Column(
        String(100),
        default="Africa's Talking"
    )


    email_provider = Column(
        String(100),
        default="SMTP"
    )


    push_provider = Column(
        String(100),
        default="Firebase"
    )


    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now()
    )


    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now()
    )