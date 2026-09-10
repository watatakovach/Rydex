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



class RideSettings(Base):

    __tablename__ = "ride_settings"


    id = Column(
        Integer,
        primary_key=True,
        index=True
    )


    # Dispatch System

    auto_assign_driver = Column(
        Boolean,
        default=True
    )


    driver_matching_method = Column(
        String(50),
        default="nearest_driver"
    )


    search_radius_km = Column(
        Float,
        default=5.0
    )


    maximum_search_radius_km = Column(
        Float,
        default=20.0
    )


    max_driver_results = Column(
        Integer,
        default=10
    )


    # Ride Lifecycle

    ride_request_timeout_seconds = Column(
        Integer,
        default=60
    )


    driver_accept_timeout_seconds = Column(
        Integer,
        default=30
    )


    driver_arrival_timeout_minutes = Column(
        Integer,
        default=10
    )


    allow_driver_reassignment = Column(
        Boolean,
        default=True
    )


    maximum_reassignments = Column(
        Integer,
        default=3
    )


    # Scheduling

    scheduled_rides_enabled = Column(
        Boolean,
        default=True
    )


    maximum_schedule_days = Column(
        Integer,
        default=30
    )


    # Cancellation

    passenger_cancel_enabled = Column(
        Boolean,
        default=True
    )


    driver_cancel_enabled = Column(
        Boolean,
        default=True
    )


    cancellation_fee_enabled = Column(
        Boolean,
        default=False
    )


    cancellation_fee_amount = Column(
        Float,
        default=0
    )


    # Safety

    sos_enabled = Column(
        Boolean,
        default=True
    )


    emergency_contact_enabled = Column(
        Boolean,
        default=True
    )


    share_trip_enabled = Column(
        Boolean,
        default=True
    )


    # Pricing Rules

    minimum_fare = Column(
        Float,
        default=100
    )


    base_fare = Column(
        Float,
        default=50
    )


    price_per_km = Column(
        Float,
        default=30
    )


    price_per_minute = Column(
        Float,
        default=5
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