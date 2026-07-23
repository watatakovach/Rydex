from math import radians, sin, cos, sqrt, atan2


BASE_FARE = 100.0
PRICE_PER_KM = 50.0
MINIMUM_FARE = 150.0


def calculate_distance_km(
    pickup_latitude: float,
    pickup_longitude: float,
    destination_latitude: float,
    destination_longitude: float,
) -> float:
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

    c = 2 * atan2(
        sqrt(a),
        sqrt(1 - a),
    )

    return earth_radius_km * c


def calculate_fare(
    distance_km: float,
) -> float:
    fare = (
        BASE_FARE
        + distance_km * PRICE_PER_KM
    )

    return round(
        max(fare, MINIMUM_FARE),
        2,
    )