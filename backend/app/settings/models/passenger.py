from sqlalchemy import (
    Column,
    Integer,
    String,
    Boolean,
    Float,
    DateTime,
    func,
)

from app.database.database import Base



class PassengerSettings(Base):

    __tablename__ = "passenger_settings"


    id = Column(
        Integer,
        primary_key=True,
        index=True
    )


    # Registration

    passenger_registration_enabled = Column(
        Boolean,
        default=True
    )


    require_phone_verification = Column(
        Boolean,
        default=True
    )


    require_email_verification = Column(
        Boolean,
        default=False
    )


    allow_social_login = Column(
        Boolean,
        default=False
    )


    # Account Management

    allow_multiple_accounts = Column(
        Boolean,
        default=False
    )


    auto_suspend_after_reports = Column(
        Boolean,
        default=False
    )


    maximum_account_reports = Column(
        Integer,
        default=5
    )


    # Ride Rules

    maximum_active_rides = Column(
        Integer,
        default=1
    )


    allow_scheduled_rides = Column(
        Boolean,
        default=True
    )


    allow_cancel_ride = Column(
        Boolean,
        default=True
    )


    cancellation_limit_per_day = Column(
        Integer,
        default=5
    )


    # Wallet

    wallet_enabled = Column(
        Boolean,
        default=True
    )


    minimum_wallet_balance = Column(
        Float,
        default=0
    )


    maximum_wallet_balance = Column(
        Float,
        default=100000
    )


    # Ratings

    allow_passenger_rating = Column(
        Boolean,
        default=True
    )


    require_rating_after_ride = Column(
        Boolean,
        default=False
    )


    # Safety

    emergency_contact_enabled = Column(
        Boolean,
        default=True
    )


    trip_sharing_enabled = Column(
        Boolean,
        default=True
    )


    # Notifications

    ride_status_notifications = Column(
        Boolean,
        default=True
    )


    promotional_notifications = Column(
        Boolean,
        default=True
    )


    payment_notifications = Column(
        Boolean,
        default=True
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