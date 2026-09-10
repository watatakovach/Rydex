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



class MapSettings(Base):

    __tablename__ = "map_settings"


    id = Column(
        Integer,
        primary_key=True,
        index=True
    )


    # Map Provider

    map_provider = Column(
        String(100),
        default="Google Maps"
    )


    google_maps_enabled = Column(
        Boolean,
        default=True
    )


    map_api_key = Column(
        String(255),
        nullable=True
    )


    # Default Location

    default_country = Column(
        String(100),
        default="Kenya"
    )


    default_city = Column(
        String(100),
        default="Nairobi"
    )


    default_latitude = Column(
        Float,
        default=-1.286389
    )


    default_longitude = Column(
        Float,
        default=36.817223
    )


    # Driver Tracking

    driver_location_tracking = Column(
        Boolean,
        default=True
    )


    location_update_interval_seconds = Column(
        Integer,
        default=10
    )


    driver_online_radius_km = Column(
        Float,
        default=20
    )


    # Ride Matching

    calculate_distance_automatically = Column(
        Boolean,
        default=True
    )


    use_road_distance = Column(
        Boolean,
        default=True
    )


    maximum_pickup_distance_km = Column(
        Float,
        default=50
    )


    # Geofencing

    geofencing_enabled = Column(
        Boolean,
        default=False
    )


    service_area_radius_km = Column(
        Float,
        default=50
    )


    restrict_outside_service_area = Column(
        Boolean,
        default=False
    )


    # Location Privacy

    require_location_permission = Column(
        Boolean,
        default=True
    )


    store_location_history = Column(
        Boolean,
        default=True
    )


    location_history_days = Column(
        Integer,
        default=30
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