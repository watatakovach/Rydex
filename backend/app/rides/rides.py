from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.database.database import get_db
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
    # --------------------------------------------------------
    # ONLY PASSENGERS CAN REQUEST RIDES
    # --------------------------------------------------------

    if current_user.role != "passenger":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only passengers can request rides",
        )

    # --------------------------------------------------------
    # CALCULATE DISTANCE
    # --------------------------------------------------------

    distance_km = calculate_distance_km(
    ride_data.pickup_latitude,
    ride_data.pickup_longitude,
    ride_data.destination_latitude,
    ride_data.destination_longitude,
    )

    # --------------------------------------------------------
    # CALCULATE ESTIMATED FARE
    # --------------------------------------------------------

    estimated_fare = calculate_fare(
    distance_km,
    db,
)

    # --------------------------------------------------------
    # FIND NEAREST AVAILABLE DRIVER
    #
    # IMPORTANT:
    # find_nearest_driver() returns a Driver object.
    #
    # Driver.id     -> stored in Ride.driver_id
    # Driver.user_id -> used for WebSocket notifications
    # --------------------------------------------------------

    nearest_driver, driver_distance = find_nearest_driver(
        db,
        ride_data.pickup_latitude,
        ride_data.pickup_longitude,
    )

    # --------------------------------------------------------
    # DETERMINE INITIAL RIDE STATUS
    # --------------------------------------------------------

    if nearest_driver:
        initial_status = "assigned"
        assigned_driver_id = nearest_driver.id
    else:
        initial_status = "requested"
        assigned_driver_id = None

    # --------------------------------------------------------
    # CREATE RIDE
    # --------------------------------------------------------

    new_ride = Ride(
        passenger_id=current_user.id,

        # IMPORTANT:
        # Ride.driver_id stores Driver.id,
        # NOT Driver.user_id.
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

    # --------------------------------------------------------
    # NOTIFY AUTOMATICALLY ASSIGNED DRIVER
    # --------------------------------------------------------

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
    # --------------------------------------------------------
    # FIND DRIVER PROFILE USING USER ID
    # --------------------------------------------------------

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

    # --------------------------------------------------------
    # DRIVER MUST BE VERIFIED
    # --------------------------------------------------------

    if not driver.is_verified:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Driver is not verified",
        )

    # --------------------------------------------------------
    # DRIVER MUST BE ONLINE
    # --------------------------------------------------------

    if not driver.is_online:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Driver is offline",
        )

    # --------------------------------------------------------
    # GET UNASSIGNED REQUESTED RIDES
    # --------------------------------------------------------

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
    response_model=RideAcceptResponse,
)
async def accept_ride(
    ride_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # --------------------------------------------------------
    # FIND DRIVER PROFILE
    # --------------------------------------------------------

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

    # --------------------------------------------------------
    # DRIVER MUST BE VERIFIED
    # --------------------------------------------------------

    if not driver.is_verified:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Driver is not verified",
        )

    # --------------------------------------------------------
    # DRIVER MUST BE ONLINE
    # --------------------------------------------------------

    if not driver.is_online:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Driver is offline",
        )

    # --------------------------------------------------------
    # FIND RIDE
    # --------------------------------------------------------

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

    # --------------------------------------------------------
    # RIDE MUST STILL BE REQUESTED
    # --------------------------------------------------------

    if ride.status != "requested":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ride is no longer available",
        )

    # --------------------------------------------------------
    # RIDE MUST NOT HAVE A DRIVER
    # --------------------------------------------------------

    if ride.driver_id is not None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ride has already been assigned",
        )

    # --------------------------------------------------------
    # ASSIGN DRIVER
    #
    # IMPORTANT:
    # Store Driver.id in Ride.driver_id.
    # --------------------------------------------------------

    ride.driver_id = driver.id
    ride.status = "accepted"

    db.commit()
    db.refresh(ride)

    # --------------------------------------------------------
    # NOTIFY PASSENGER
    # --------------------------------------------------------

    await manager.send_to_user(
        ride.passenger_id,
        {
            "type": "ride_accepted",
            "message": "Your driver has accepted the ride",

            "ride_id": ride.id,

            "driver_id": driver.id,

            # This is the driver's User.id.
            # Useful if the passenger needs the user account ID.
            "driver_user_id": driver.user_id,

            "status": ride.status,
        },
    )

    return ride


# ============================================================
# UPDATE RIDE STATUS
# DRIVER STATUS UPDATES + PASSENGER CANCELLATION
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

    # --------------------------------------------------------
    # FIND RIDE
    # --------------------------------------------------------

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

        # ----------------------------------------------------
        # SAVE DRIVER ID BEFORE CLEARING IT
        # ----------------------------------------------------

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

        # ----------------------------------------------------
        # CANCEL RIDE
        # ----------------------------------------------------

        ride.status = "cancelled"

        # Remove driver assignment
        ride.driver_id = None

        db.commit()
        db.refresh(ride)

        # ----------------------------------------------------
        # NOTIFY DRIVER
        # ----------------------------------------------------

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

    # --------------------------------------------------------
    # RIDE MUST HAVE A DRIVER
    # --------------------------------------------------------

    if ride.driver_id is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ride has no assigned driver",
        )

    # --------------------------------------------------------
    # FIND DRIVER PROFILE USING CURRENT USER
    # --------------------------------------------------------

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

    # --------------------------------------------------------
    # ONLY ASSIGNED DRIVER CAN UPDATE RIDE
    #
    # ride.driver_id = Driver.id
    # driver.id      = Driver.id
    # --------------------------------------------------------

    if driver.id != ride.driver_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You are not the assigned driver",
        )

    # --------------------------------------------------------
    # VALID STATUS TRANSITIONS
    # --------------------------------------------------------

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

    # --------------------------------------------------------
    # UPDATE STATUS
    # --------------------------------------------------------

    ride.status = new_status

    # --------------------------------------------------------
    # COMPLETION TIME
    # --------------------------------------------------------

    if new_status == "completed":
        ride.completed_at = datetime.now(
            timezone.utc
        )

    # --------------------------------------------------------
    # DRIVER DECLINE (auto-assigned ride, not yet accepted)
    #
    # If a driver cancels a ride that was auto-assigned to
    # them (status was "assigned", meaning they never
    # explicitly accepted), try to find the next-nearest
    # driver instead of forcing the passenger to re-request.
    # --------------------------------------------------------

    if new_status == "cancelled" and current_status == "assigned":
        declined_driver_id = driver.id

        new_driver, _ = find_nearest_driver(
            db,
            ride.pickup_latitude,
            ride.pickup_longitude,
            exclude_driver_id=declined_driver_id,
        )

        if new_driver:
            # Re-assign to the next-nearest driver
            ride.driver_id = new_driver.id
            ride.status = "assigned"

            db.commit()
            db.refresh(ride)

            # Notify the newly assigned driver
            await manager.send_to_user(
                new_driver.user_id,
                {
                    "type": "new_ride_request",
                    "message": "You have a new ride request",
                    "ride_id": ride.id,
                    "driver_id": new_driver.id,
                    "pickup": {
                        "latitude": ride.pickup_latitude,
                        "longitude": ride.pickup_longitude,
                    },
                    "destination": {
                        "latitude": ride.destination_latitude,
                        "longitude": ride.destination_longitude,
                    },
                    "estimated_fare": ride.estimated_fare,
                    "status": ride.status,
                },
            )

            # Let the passenger know a new driver was assigned
            await manager.send_to_user(
                ride.passenger_id,
                {
                    "type": "ride_status_update",
                    "message": "A new driver has been assigned to your ride",
                    "ride_id": ride.id,
                    "status": ride.status,
                    "driver_id": new_driver.id,
                },
            )

            return ride

        # No other driver available -> fall back to
        # "requested" so it reappears in /rides/available
        ride.driver_id = None
        ride.status = "requested"

        db.commit()
        db.refresh(ride)

        await manager.send_to_user(
            ride.passenger_id,
            {
                "type": "ride_status_update",
                "message": "Looking for another driver...",
                "ride_id": ride.id,
                "status": ride.status,
                "driver_id": None,
            },
        )

        return ride

    # --------------------------------------------------------
    # NORMAL DRIVER CANCELLATION
    # (ride was already accepted or further along)
    # --------------------------------------------------------

    if new_status == "cancelled":
        ride.driver_id = None

    db.commit()
    db.refresh(ride)

    # --------------------------------------------------------
    # NOTIFY PASSENGER
    # --------------------------------------------------------

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
# GET MY RIDES
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
# GET CURRENT RIDE
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
    # --------------------------------------------------------
    # FIND DRIVER PROFILE
    # --------------------------------------------------------

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

    # --------------------------------------------------------
    # GET DRIVER'S COMPLETED/CANCELLED RIDES
    # --------------------------------------------------------

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