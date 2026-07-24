from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.database.connection import get_db
from app.users.models import User
from app.drivers.models import Driver
from app.rides.models import Ride
from app.rides.schemas import (
    RideRequest,
    RideResponse,
    RideAcceptResponse,
    RideStatusUpdate,
)
from app.rides.fare import (
    calculate_distance_km,
    calculate_fare,
)
from app.rides.matching import find_nearest_driver
from app.notifications.websocket_manager import manager


router = APIRouter(
    prefix="/rides",
    tags=["Rides"],
)


# ============================================================
# REQUEST RIDE
# ============================================================

@router.post(
    "/request",
    response_model=RideResponse,
    status_code=status.HTTP_201_CREATED,
)
async def request_ride(
    ride_data: RideRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.role != "passenger":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only passengers can request rides",
        )

    distance_km = calculate_distance_km(
        ride_data.pickup_latitude,
        ride_data.pickup_longitude,
        ride_data.destination_latitude,
        ride_data.destination_longitude,
    )

    estimated_fare = calculate_fare(distance_km)

    nearest_driver, driver_distance = find_nearest_driver(
        db,
        ride_data.pickup_latitude,
        ride_data.pickup_longitude,
    )

    if nearest_driver:
        initial_status = "assigned"
        assigned_driver_id = nearest_driver.id
    else:
        initial_status = "requested"
        assigned_driver_id = None

    new_ride = Ride(
        passenger_id=current_user.id,
        driver_id=assigned_driver_id,

        pickup_latitude=ride_data.pickup_latitude,
        pickup_longitude=ride_data.pickup_longitude,

        destination_latitude=ride_data.destination_latitude,
        destination_longitude=ride_data.destination_longitude,

        status=initial_status,
        estimated_fare=estimated_fare,
    )

    db.add(new_ride)
    db.commit()
    db.refresh(new_ride)

    if nearest_driver:
        await manager.send_to_user(
            nearest_driver.user_id,
            {
                "type": "new_ride_request",
                "message": "You have a new ride request",
                "ride_id": new_ride.id,
                "driver_id": nearest_driver.id,

                "pickup": {
                    "latitude": new_ride.pickup_latitude,
                    "longitude": new_ride.pickup_longitude,
                },

                "destination": {
                    "latitude": new_ride.destination_latitude,
                    "longitude": new_ride.destination_longitude,
                },

                "estimated_fare": new_ride.estimated_fare,
                "status": new_ride.status,
            },
        )

    return new_ride


# ============================================================
# GET AVAILABLE RIDES
# ============================================================

@router.get(
    "/available",
    response_model=list[RideResponse],
)
def get_available_rides(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    driver = (
        db.query(Driver)
        .filter(
            Driver.user_id == current_user.id
        )
        .first()
    )

    if not driver:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Driver profile not found",
        )

    if not driver.is_verified:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Driver is not verified",
        )

    if not driver.is_online:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Driver is offline",
        )

    rides = (
        db.query(Ride)
        .filter(
            Ride.status == "requested",
            Ride.driver_id.is_(None),
        )
        .order_by(
            Ride.requested_at.desc()
        )
        .all()
    )

    return rides


# ============================================================
# ACCEPT RIDE
# ============================================================

@router.patch(
    "/{ride_id}/accept",
    response_model=RideResponse,
)
async def accept_ride(
    ride_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    driver = (
        db.query(Driver)
        .filter(
            Driver.user_id == current_user.id
        )
        .first()
    )

    if not driver:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Driver profile not found",
        )

    if not driver.is_verified:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Driver is not verified",
        )

    if not driver.is_online:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Driver is offline",
        )

    ride = (
        db.query(Ride)
        .filter(
            Ride.id == ride_id
        )
        .first()
    )

    if not ride:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ride not found",
        )

    if ride.status != "requested":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ride is no longer available",
        )

    if ride.driver_id is not None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ride has already been assigned",
        )

    ride.driver_id = driver.id
    ride.status = "accepted"

    db.commit()
    db.refresh(ride)

    await manager.send_to_user(
        ride.passenger_id,
        {
            "type": "ride_accepted",
            "message": "Your driver has accepted the ride",
            "ride_id": ride.id,
            "driver_id": driver.id,
            "driver_user_id": driver.user_id,
            "status": ride.status,
        },
    )

    return ride


# ============================================================
# UPDATE RIDE STATUS
# ============================================================

@router.patch(
    "/{ride_id}/status",
    response_model=RideResponse,
)
async def update_ride_status(
    ride_id: int,
    status_data: RideStatusUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    new_status = status_data.status

    ride = (
        db.query(Ride)
        .filter(
            Ride.id == ride_id
        )
        .first()
    )

    if not ride:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ride not found",
        )

    # ========================================================
    # PASSENGER CANCELLATION
    # ========================================================

    if (
        new_status == "cancelled"
        and ride.passenger_id == current_user.id
    ):
        cancellable_statuses = [
            "requested",
            "assigned",
            "accepted",
            "driver_arriving",
            "driver_arrived",
        ]

        if ride.status not in cancellable_statuses:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Ride cannot be cancelled at this stage",
            )

        old_driver_id = ride.driver_id

        driver_user_id = None

        if old_driver_id is not None:
            old_driver = (
                db.query(Driver)
                .filter(
                    Driver.id == old_driver_id
                )
                .first()
            )

            if old_driver:
                driver_user_id = old_driver.user_id

        ride.status = "cancelled"
        ride.driver_id = None

        db.commit()
        db.refresh(ride)

        if driver_user_id is not None:
            await manager.send_to_user(
                driver_user_id,
                {
                    "type": "ride_cancelled",
                    "message": "The passenger cancelled the ride",
                    "ride_id": ride.id,
                    "status": ride.status,
                },
            )

        return ride

    # ========================================================
    # DRIVER STATUS UPDATE
    # ========================================================

    if ride.driver_id is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ride has no assigned driver",
        )

    driver = (
        db.query(Driver)
        .filter(
            Driver.user_id == current_user.id
        )
        .first()
    )

    if not driver:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Driver profile not found",
        )

    if driver.id != ride.driver_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You are not the assigned driver",
        )

    # ========================================================
    # VALID RIDE FLOW
    # ========================================================

    valid_transitions = {
        "assigned": [
            "accepted",
            "cancelled",
        ],

        "accepted": [
            "driver_arriving",
            "cancelled",
        ],

        "driver_arriving": [
            "driver_arrived",
            "cancelled",
        ],

        "driver_arrived": [
            "in_progress",
            "cancelled",
        ],

        "in_progress": [
            "completed",
        ],
    }

    current_status = ride.status

    if current_status not in valid_transitions:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                f"Ride cannot be updated from "
                f"status '{current_status}'"
            ),
        )

    if new_status not in valid_transitions[current_status]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                f"Cannot change ride from "
                f"{current_status} to "
                f"{new_status}"
            ),
        )

    ride.status = new_status

    if new_status == "completed":
        ride.completed_at = datetime.now(
            timezone.utc
        )

    if new_status == "completed":
        # Keep driver_id so ride history can find it.
        pass

    if new_status == "cancelled":
        ride.driver_id = None

    db.commit()
    db.refresh(ride)

    await manager.send_to_user(
        ride.passenger_id,
        {
            "type": "ride_status_update",
            "message": "Your ride status has changed",
            "ride_id": ride.id,
            "status": ride.status,
            "driver_id": driver.id,
        },
    )

    return ride


# ============================================================
# GET MY RIDES - PASSENGER
# ============================================================

@router.get(
    "/my-rides",
    response_model=list[RideResponse],
)
def get_my_rides(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    rides = (
        db.query(Ride)
        .filter(
            Ride.passenger_id == current_user.id
        )
        .order_by(
            Ride.requested_at.desc()
        )
        .all()
    )

    return rides


# ============================================================
# GET CURRENT RIDE - PASSENGER
# ============================================================

@router.get(
    "/current",
    response_model=RideResponse,
)
def get_current_ride(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    active_statuses = [
        "requested",
        "assigned",
        "accepted",
        "driver_arriving",
        "driver_arrived",
        "in_progress",
    ]

    ride = (
        db.query(Ride)
        .filter(
            Ride.passenger_id == current_user.id,
            Ride.status.in_(active_statuses),
        )
        .order_by(
            Ride.requested_at.desc()
        )
        .first()
    )

    if not ride:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No active ride found",
        )

    return ride


# ============================================================
# GET DRIVER CURRENT ACTIVE RIDE
# ============================================================

@router.get(
    "/driver/current",
    response_model=RideResponse,
)
def get_driver_current_ride(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    driver = (
        db.query(Driver)
        .filter(
            Driver.user_id == current_user.id
        )
        .first()
    )

    if not driver:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Driver profile not found",
        )

    active_statuses = [
        "assigned",
        "accepted",
        "driver_arriving",
        "driver_arrived",
        "in_progress",
    ]

    ride = (
        db.query(Ride)
        .filter(
            Ride.driver_id == driver.id,
            Ride.status.in_(active_statuses),
        )
        .order_by(
            Ride.requested_at.desc()
        )
        .first()
    )

    if not ride:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No active ride found",
        )

    return ride


# ============================================================
# DRIVER RIDE HISTORY
# ============================================================

@router.get(
    "/driver/history",
    response_model=list[RideResponse],
)
def get_driver_history(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    driver = (
        db.query(Driver)
        .filter(
            Driver.user_id == current_user.id
        )
        .first()
    )

    if not driver:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Driver profile not found",
        )

    rides = (
        db.query(Ride)
        .filter(
            Ride.driver_id == driver.id,
            Ride.status.in_([
                "completed",
                "cancelled",
            ]),
        )
        .order_by(
            Ride.requested_at.desc()
        )
        .all()
    )

    return rides