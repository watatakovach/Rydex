from datetime import datetime

from pydantic import BaseModel, ConfigDict


class MapSettingsBase(BaseModel):
    # Map Provider
    map_provider: str = "Google Maps"
    google_maps_enabled: bool = True
    map_api_key: str | None = None

    # Default Location
    default_country: str = "Kenya"
    default_city: str = "Nairobi"
    default_latitude: float = -1.286389
    default_longitude: float = 36.817223

    # Driver Tracking
    driver_location_tracking: bool = True
    location_update_interval_seconds: int = 10
    driver_online_radius_km: float = 20

    # Ride Matching
    calculate_distance_automatically: bool = True
    use_road_distance: bool = True
    maximum_pickup_distance_km: float = 50

    # Geofencing
    geofencing_enabled: bool = False
    service_area_radius_km: float = 50
    restrict_outside_service_area: bool = False

    # Location Privacy
    require_location_permission: bool = True
    store_location_history: bool = True
    location_history_days: int = 30


class MapSettingsCreate(MapSettingsBase):
    pass


class MapSettingsUpdate(BaseModel):
    map_provider: str | None = None
    google_maps_enabled: bool | None = None
    map_api_key: str | None = None

    default_country: str | None = None
    default_city: str | None = None
    default_latitude: float | None = None
    default_longitude: float | None = None

    driver_location_tracking: bool | None = None
    location_update_interval_seconds: int | None = None
    driver_online_radius_km: float | None = None

    calculate_distance_automatically: bool | None = None
    use_road_distance: bool | None = None
    maximum_pickup_distance_km: float | None = None

    geofencing_enabled: bool | None = None
    service_area_radius_km: float | None = None
    restrict_outside_service_area: bool | None = None

    require_location_permission: bool | None = None
    store_location_history: bool | None = None
    location_history_days: int | None = None


class MapSettingsResponse(MapSettingsBase):
    id: int
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(
        from_attributes=True
    )