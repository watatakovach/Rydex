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



class DriverSettings(Base):

    __tablename__ = "driver_settings"


    id = Column(
        Integer,
        primary_key=True,
        index=True
    )


    # Registration

    driver_registration_enabled = Column(
        Boolean,
        default=True
    )


    auto_approve_driver = Column(
        Boolean,
        default=False
    )


    require_admin_verification = Column(
        Boolean,
        default=True
    )


    # Documents

    require_driving_license = Column(
        Boolean,
        default=True
    )


    require_vehicle_documents = Column(
        Boolean,
        default=True
    )
    
    require_vehicle_verification = Column(
        Boolean,
        default=True
    )


    require_profile_photo = Column(
        Boolean,
        default=True
    )


    document_expiry_check = Column(
        Boolean,
        default=True
    )
    
    require_national_id = Column(
        Boolean,
        default=True
    )
    
    


    # Driver Availability

    allow_driver_online = Column(
        Boolean,
        default=True
    )


    require_location_tracking = Column(
        Boolean,
        default=True
    )


    offline_timeout_minutes = Column(
        Integer,
        default=15
    )


    # Ratings

    minimum_driver_rating = Column(
        Float,
        default=3.5
    )


    rating_warning_threshold = Column(
        Float,
        default=3.0
    )


    suspend_low_rating_driver = Column(
        Boolean,
        default=False
    )
    
    driver_commission_percentage = Column(
        Float,
        default=20.0
    )

    


    minimum_driver_balance = Column(
        Float,
        default=0
    )


    # Ride Limits

    maximum_active_rides = Column(
        Integer,
        default=1
    )


    allow_multiple_vehicle = Column(
        Boolean,
        default=False
    )


    # Notifications

    notify_new_ride_requests = Column(
        Boolean,
        default=True
    )


    notify_payment_updates = Column(
        Boolean,
        default=True
    )


    notify_document_expiry = Column(
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