
from math import atan2, cos, radians, sin, sqrt

from sqlalchemy.orm import Session

from app.settings.models.ride import RideSettings


# ============================================================
# DISTANCE CALCULATION
# ============================================================


def calculate_distance_km(
    pickup_latitude: float,
    pickup_longitude: float,
    destination_latitude: float,
    destination_longitude: float,
) -> float:
    """
    Calculate straight-line distance between pickup
    and destination using the Haversine formula.

    Returns:
        Distance in kilometres, rounded to 2 decimals.
    """

    earth_radius_km = 6371.0

    lat1 = radians(pickup_latitude)
    lat2 = radians(destination_latitude)

    delta_lat = radians(
        destination_latitude - pickup_latitude
    )

    delta_lon = radians(
        destination_longitude - pickup_longitude
    )

    a = (
        sin(delta_lat / 2) ** 2
        + cos(lat1)
        * cos(lat2)
        * sin(delta_lon / 2) ** 2
    )

    # Protect against tiny floating-point errors.
    a = min(1.0, max(0.0, a))

    c = 2 * atan2(
        sqrt(a),
        sqrt(1 - a),
    )

    return round(
        earth_radius_km * c,
        2,
    )


# ============================================================
# GET RIDE SETTINGS
# ============================================================


def get_ride_settings(
    db: Session,
) -> RideSettings:
    """
    Return the current RideSettings row.

    RYDEX uses the dedicated RideSettings table as the
    single source of truth for ride/fare configuration.

    If no settings row exists, create one using the model
    defaults.
    """

    settings = (
        db.query(RideSettings)
        .order_by(RideSettings.id.asc())
        .first()
    )

    if settings is None:
        settings = RideSettings()

        db.add(settings)
        db.commit()
        db.refresh(settings)

    return settings


# ============================================================
# FARE VALIDATION
# ============================================================


def _validate_fare_settings(
    settings: RideSettings,
) -> None:
    """
    Validate fare settings before calculating a fare.

    Raises:
        ValueError: If a fare setting is invalid.
    """

    if settings.base_fare < 0:
        raise ValueError(
            "base_fare cannot be negative"
        )

    if settings.price_per_km < 0:
        raise ValueError(
            "price_per_km cannot be negative"
        )

    if settings.minimum_fare < 0:
        raise ValueError(
            "minimum_fare cannot be negative"
        )

    if settings.minimum_fare < settings.base_fare:
        raise ValueError(
            "minimum_fare cannot be lower than base_fare"
        )


# ============================================================
# FARE CALCULATION
# ============================================================


def calculate_fare(
    db: Session,
    distance_km: float,
) -> float:
    """
    Calculate the estimated ride fare.

    Formula:

        distance_charge = distance_km * price_per_km

        calculated_fare = base_fare + distance_charge

        final_fare = max(
            calculated_fare,
            minimum_fare,
        )

    Args:
        db:
            SQLAlchemy database session.

        distance_km:
            Ride distance in kilometres.

    Returns:
        Estimated fare rounded to 2 decimal places.
    """

    if distance_km < 0:
        raise ValueError(
            "Distance cannot be negative"
        )

    settings = get_ride_settings(db)

    _validate_fare_settings(settings)

    distance_charge = (
        distance_km
        * settings.price_per_km
    )

    calculated_fare = (
        settings.base_fare
        + distance_charge
    )

    final_fare = max(
        calculated_fare,
        settings.minimum_fare,
    )

    return round(
        final_fare,
        2,
    )


# ============================================================
# FARE BREAKDOWN
# ============================================================


def calculate_fare_breakdown(
    db: Session,
    distance_km: float,
) -> dict:
    """
    Calculate a complete fare breakdown.

    Returns:

        {
            "base_fare": ...,
            "distance_km": ...,
            "price_per_km": ...,
            "distance_charge": ...,
            "minimum_fare": ...,
            "calculated_fare": ...,
            "total_fare": ...
        }
    """

    if distance_km < 0:
        raise ValueError(
            "Distance cannot be negative"
        )

    settings = get_ride_settings(db)

    _validate_fare_settings(settings)

    distance_charge = (
        distance_km
        * settings.price_per_km
    )

    calculated_fare = (
        settings.base_fare
        + distance_charge
    )

    final_fare = max(
        calculated_fare,
        settings.minimum_fare,
    )

    return {
        "base_fare": round(
            settings.base_fare,
            2,
        ),
        "distance_km": round(
            distance_km,
            2,
        ),
        "price_per_km": round(
            settings.price_per_km,
            2,
        ),
        "distance_charge": round(
            distance_charge,
            2,
        ),
        "minimum_fare": round(
            settings.minimum_fare,
            2,
        ),
        "calculated_fare": round(
            calculated_fare,
            2,
        ),
        "total_fare": round(
            final_fare,
            2,
        ),
    }

