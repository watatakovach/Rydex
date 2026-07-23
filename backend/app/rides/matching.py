from math import radians, sin, cos, sqrt, atan2

from sqlalchemy.orm import Session

from app.drivers.models import Driver
from app.drivers.location_models import DriverLocation
from app.rides.models import Ride


ACTIVE_RIDE_STATUSES = [
    "assigned",
    "accepted",
    "driver_arriving",
    "driver_arrived",
    "in_progress",
]


def calculate_distance_km(
    lat1: float,
    lon1: float,
    lat2: float,
    lon2: float,
) -> float:
    """
    Calculate the distance between two GPS coordinates
    using the Haversine formula.
    """

    earth_radius_km = 6371.0

    lat1_rad = radians(lat1)
    lat2_rad = radians(lat2)

    delta_lat = radians(lat2 - lat1)
    delta_lon = radians(lon2 - lon1)

    a = (
        sin(delta_lat / 2) ** 2
        + cos(lat1_rad)
        * cos(lat2_rad)
        * sin(delta_lon / 2) ** 2
    )

    c = 2 * atan2(
        sqrt(a),
        sqrt(1 - a),
    )

    return earth_radius_km * c


def find_nearest_driver(
    db: Session,
    pickup_latitude: float,
    pickup_longitude: float,
    exclude_driver_id: int | None = None,
):
    """
    Find and LOCK the nearest verified, online, and
    currently unassigned driver.

    IMPORTANT:
    This must be called from inside the same transaction
    that will create/update the Ride row (i.e. before
    db.commit()). The lock is held until that transaction
    commits or rolls back, which prevents two concurrent
    requests from matching the same driver.

    exclude_driver_id:
        Optional Driver.id to exclude from matching.
        Used when re-matching after a driver declines/
        cancels an auto-assigned ride, so they aren't
        immediately re-matched to the same ride.
    """

    busy_driver_ids = (
        db.query(Ride.driver_id)
        .filter(
            Ride.driver_id.isnot(None),
            Ride.status.in_(ACTIVE_RIDE_STATUSES),
        )
    )

    query = (
        db.query(Driver)
        .filter(
            Driver.is_verified.is_(True),
            Driver.is_online.is_(True),
            ~Driver.id.in_(busy_driver_ids),
        )
    )

    if exclude_driver_id is not None:
        query = query.filter(Driver.id != exclude_driver_id)

    # Lock candidate driver rows so no other transaction
    # can select the same driver until we commit.
    # NOTE: requires Postgres (or another DB supporting
    # SELECT ... FOR UPDATE SKIP LOCKED). Not supported by
    # SQLite.
    drivers = query.with_for_update(skip_locked=True).all()

    nearest_driver = None
    nearest_distance = None

    for driver in drivers:
        location = (
            db.query(DriverLocation)
            .filter(
                DriverLocation.driver_id == driver.id
            )
            .first()
        )

        if not location:
            continue

        distance = calculate_distance_km(
            pickup_latitude,
            pickup_longitude,
            location.latitude,
            location.longitude,
        )

        if (
            nearest_distance is None
            or distance < nearest_distance
        ):
            nearest_driver = driver
            nearest_distance = distance

    return nearest_driver, nearest_distance