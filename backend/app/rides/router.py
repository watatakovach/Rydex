
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
    RideStatusUpdate,
)
from app.rides.fare import (
    calculate_distance_km,
    calculate_fare,
)
from app.rides.matching import find_nearest_driver
from app.rides.notifications import notify_ride_event
from app.payments.models import Payment
from app.ratings.models import DriverRating
from app.ratings.schemas import (
    DriverRatingCreate,
    DriverRatingResponse,
)


router = APIRouter(
    prefix="/rides",
    tags=["Rides"],
)


# ============================================================
# RIDE STATUS CONSTANTS
# ============================================================

ACTIVE_RIDE_STATUSES = [
    "assigned",
    "accepted",
    "driver_arriving",
    "driver_arrived",
    "in_progress",
]

PASSENGER_ACTIVE_STATUSES = [
    "requested",
    "assigned",
    "accepted",
    "driver_arriving",
    "driver_arrived",
    "in_progress",
]

COMPLETED_STATUSES = [
    "completed",
    "cancelled",
]


def attach_rating_fields(
    ride: Ride,
    db: Session,
):
    rating = (
        db.query(DriverRating)
        .filter(DriverRating.ride_id == ride.id)
        .first()
    )

    ride.driver_rating = rating.rating if rating else None
    ride.driver_rating_comment = rating.comment if rating else None
    ride.has_driver_rating = rating is not None

    return ride


def attach_rating_fields_many(
    rides: list[Ride],
    db: Session,
):
    if not rides:
        return rides

    ride_ids = [ride.id for ride in rides]

    ratings = (
        db.query(DriverRating)
        .filter(DriverRating.ride_id.in_(ride_ids))
        .all()
    )

    ratings_by_ride_id = {
        rating.ride_id: rating
        for rating in ratings
    }

    for ride in rides:
        rating = ratings_by_ride_id.get(ride.id)
        ride.driver_rating = rating.rating if rating else None
        ride.driver_rating_comment = rating.comment if rating else None
        ride.has_driver_rating = rating is not None

    return rides


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

    # Prevent multiple active rides.
    existing_active_ride = (
        db.query(Ride)
        .filter(
            Ride.passenger_id == current_user.id,
            Ride.status.in_(PASSENGER_ACTIVE_STATUSES),
        )
        .first()
    )

    if existing_active_ride:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "You already have an active ride. "
                "Complete or cancel it before requesting another ride."
            ),
        )

    # Calculate distance.
    distance_km = calculate_distance_km(
        ride_data.pickup_latitude,
        ride_data.pickup_longitude,
        ride_data.destination_latitude,
        ride_data.destination_longitude,
    )

    # Calculate estimated fare.
    estimated_fare = calculate_fare(
        distance_km,
        db,
    )

    # Find nearest available driver.
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
        distance_km=distance_km,
    )

    db.add(new_ride)
    db.commit()
    db.refresh(new_ride)

    # Notify assigned driver.
    if nearest_driver:
        await notify_ride_event(
            nearest_driver.user_id,
            {
                "type": "new_ride_request",
                "message": "You have a new ride request",
                "ride": {
                    "id": new_ride.id,
                    "passenger_id": new_ride.passenger_id,
                    "driver_id": new_ride.driver_id,
                    "status": new_ride.status,
                    "pickup": {
                        "latitude": new_ride.pickup_latitude,
                        "longitude": new_ride.pickup_longitude,
                    },
                    "destination": {
                        "latitude": new_ride.destination_latitude,
                        "longitude": new_ride.destination_longitude,
                    },
                    "estimated_fare": new_ride.estimated_fare,
                    "distance_km": new_ride.distance_km,
                },
            },
        )

    return attach_rating_fields(new_ride, db)


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

    # Driver cannot accept another active ride.
    active_ride = (
        db.query(Ride)
        .filter(
            Ride.driver_id == driver.id,
            Ride.status.in_(ACTIVE_RIDE_STATUSES),
        )
        .first()
    )

    if active_ride:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "You already have an active ride. "
                "Complete or cancel your current ride "
                "before accepting another ride."
            ),
        )

    rides = (
        db.query(Ride)
        .filter(
            (
                (Ride.status == "requested")
                & (Ride.driver_id.is_(None))
            )
            |
            (
                (Ride.status == "assigned")
                & (Ride.driver_id == driver.id)
            )
        )
        .order_by(
            Ride.requested_at.desc()
        )
        .all()
    )

    return attach_rating_fields_many(rides, db)


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

    # Prevent multiple active rides.
    active_ride = (
        db.query(Ride)
        .filter(
            Ride.driver_id == driver.id,
            Ride.status.in_(ACTIVE_RIDE_STATUSES),
        )
        .first()
    )

    if active_ride:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You already have an active ride",
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

    # Assigned to another driver.
    if (
        ride.driver_id is not None
        and ride.driver_id != driver.id
    ):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This ride is assigned to another driver",
        )

    # Only requested or assigned rides can be accepted.
    if ride.status not in [
        "requested",
        "assigned",
    ]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ride is no longer available",
        )

    ride.driver_id = driver.id
    ride.status = "accepted"
    ride.accepted_at = datetime.now(timezone.utc)

    db.commit()
    db.refresh(ride)

    # Notify passenger.
    await notify_ride_event(
        ride.passenger_id,
        {
            "type": "ride_accepted",
            "message": "Your driver has accepted the ride",
            "ride": {
                "id": ride.id,
                "passenger_id": ride.passenger_id,
                "driver_id": ride.driver_id,
                "status": ride.status,
                "estimated_fare": ride.estimated_fare,
            },
            "driver_user_id": driver.user_id,
        },
    )

    return attach_rating_fields(ride, db)


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

    new_status = status_data.status.strip().lower()

    allowed_statuses = {
        "driver_arriving",
        "driver_arrived",
        "in_progress",
        "completed",
        "cancelled",
    }

    if new_status not in allowed_statuses:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "Invalid ride status. Allowed statuses: "
                "driver_arriving, driver_arrived, "
                "in_progress, completed, cancelled"
            ),
        )

    # ========================================================
    # IDENTIFY USER
    # ========================================================

    is_passenger = (
        ride.passenger_id == current_user.id
    )

    driver = (
        db.query(Driver)
        .filter(
            Driver.user_id == current_user.id
        )
        .first()
    )

    is_driver = (
        driver is not None
        and ride.driver_id == driver.id
    )

    if not is_passenger and not is_driver:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You are not authorized to update this ride",
        )

    # ========================================================
    # CANCELLATION
    # ========================================================

    if new_status == "cancelled":

        if ride.status in [
            "completed",
            "cancelled",
        ]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Ride has already ended",
            )

        if ride.status == "in_progress":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Ride cannot be cancelled after it has started",
            )

        ride.status = "cancelled"
        ride.cancelled_at = datetime.now(timezone.utc)
        ride.cancellation_reason = (
            status_data.cancellation_reason
        )
        ride.cancelled_by = (
            "passenger"
            if is_passenger
            else "driver"
        )

        db.commit()
        db.refresh(ride)

        # Notify driver.
        if is_passenger and ride.driver_id:

            driver_record = (
                db.query(Driver)
                .filter(
                    Driver.id == ride.driver_id
                )
                .first()
            )

            if driver_record:
                await notify_ride_event(
                    driver_record.user_id,
                    {
                        "type": "ride_cancelled",
                        "message": "The passenger cancelled the ride",
                        "ride": {
                            "id": ride.id,
                            "passenger_id": ride.passenger_id,
                            "driver_id": ride.driver_id,
                            "status": ride.status,
                            "cancellation_reason": (
                                ride.cancellation_reason
                            ),
                        },
                    },
                )

        # Notify passenger.
        elif is_driver:
            await notify_ride_event(
                ride.passenger_id,
                {
                    "type": "ride_cancelled",
                    "message": "The driver cancelled the ride",
                    "ride": {
                        "id": ride.id,
                        "passenger_id": ride.passenger_id,
                        "driver_id": ride.driver_id,
                        "status": ride.status,
                        "cancellation_reason": (
                            ride.cancellation_reason
                        ),
                    },
                },
            )

        return attach_rating_fields(ride, db)

    # ========================================================
    # ONLY DRIVER CAN ADVANCE RIDE
    # ========================================================

    if not is_driver:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only the assigned driver can advance ride status",
        )

    # ========================================================
    # VALID STATUS TRANSITIONS
    # ========================================================

    valid_transitions = {
        "accepted": [
            "driver_arriving",
        ],
        "driver_arriving": [
            "driver_arrived",
        ],
        "driver_arrived": [
            "in_progress",
        ],
        "in_progress": [
            "completed",
        ],
    }

    current_status = ride.status

    if (
        current_status not in valid_transitions
        or new_status not in valid_transitions[current_status]
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                f"Cannot change ride status from "
                f"'{current_status}' to '{new_status}'"
            ),
        )

    now = datetime.now(timezone.utc)

    # ========================================================
    # UPDATE STATUS
    # ========================================================

    ride.status = new_status

    if new_status == "driver_arriving":
        pass

    elif new_status == "driver_arrived":
        pass

    elif new_status == "in_progress":
        ride.started_at = now

    elif new_status == "completed":

        ride.completed_at = now

        # ----------------------------------------------------
        # FINAL FARE
        # ----------------------------------------------------

        if ride.final_fare is None:
            ride.final_fare = ride.estimated_fare

        # ----------------------------------------------------
        # RIDE DURATION
        # ----------------------------------------------------

        if ride.started_at:
            duration_seconds = (
                ride.completed_at - ride.started_at
            ).total_seconds()

            ride.duration_minutes = max(
                0,
                duration_seconds / 60,
            )

        # ----------------------------------------------------
        # CREATE PAYMENT
        # ----------------------------------------------------

        existing_payment = (
            db.query(Payment)
            .filter(
                Payment.ride_id == ride.id
            )
            .first()
        )

        if not existing_payment:

            payment = Payment(
                ride_id=ride.id,
                passenger_id=ride.passenger_id,
                driver_id=ride.driver_id,
                amount=ride.final_fare or 0.0,
                payment_method="cash",
                status="pending",
            )

            db.add(payment)

    # ========================================================
    # SAVE CHANGES
    # ========================================================

    db.commit()
    db.refresh(ride)

    # ========================================================
    # NOTIFY PASSENGER
    # ========================================================

    messages = {
        "driver_arriving": (
            "Your driver is on the way"
        ),
        "driver_arrived": (
            "Your driver has arrived"
        ),
        "in_progress": (
            "Your ride has started"
        ),
        "completed": (
            "Your ride has been completed"
        ),
    }

    await notify_ride_event(
        ride.passenger_id,
        {
            "type": f"ride_{new_status}",
            "message": messages.get(
                new_status,
                f"Ride status changed to {new_status}",
            ),
            "ride": {
                "id": ride.id,
                "passenger_id": ride.passenger_id,
                "driver_id": ride.driver_id,
                "status": ride.status,
                "estimated_fare": ride.estimated_fare,
                "final_fare": ride.final_fare,
                "distance_km": ride.distance_km,
                "duration_minutes": ride.duration_minutes,
                "started_at": (
                    ride.started_at.isoformat()
                    if ride.started_at
                    else None
                ),
                "completed_at": (
                    ride.completed_at.isoformat()
                    if ride.completed_at
                    else None
                ),
            },
        },
    )

    return attach_rating_fields(ride, db)


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

    return attach_rating_fields_many(rides, db)


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
    ride = (
        db.query(Ride)
        .filter(
            Ride.passenger_id == current_user.id,
            Ride.status.in_(PASSENGER_ACTIVE_STATUSES),
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

    return attach_rating_fields(ride, db)


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

    ride = (
        db.query(Ride)
        .filter(
            Ride.driver_id == driver.id,
            Ride.status.in_(ACTIVE_RIDE_STATUSES),
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

    return attach_rating_fields(ride, db)


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
            Ride.status.in_(COMPLETED_STATUSES),
        )
        .order_by(
            Ride.requested_at.desc()
        )
        .all()
    )

    return attach_rating_fields_many(rides, db)


# ============================================================
# GET SINGLE RIDE
# ============================================================

@router.get(
    "/{ride_id}",
    response_model=RideResponse,
)
def get_ride(
    ride_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
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

    is_passenger = (
        ride.passenger_id == current_user.id
    )

    driver = (
        db.query(Driver)
        .filter(
            Driver.user_id == current_user.id
        )
        .first()
    )

    is_driver = (
        driver is not None
        and ride.driver_id == driver.id
    )

    if not is_passenger and not is_driver:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You are not authorized to view this ride",
        )

    return attach_rating_fields(ride, db)


# ============================================================
# RATE COMPLETED RIDE DRIVER
# ============================================================

@router.post(
    "/{ride_id}/rating",
    response_model=DriverRatingResponse,
    status_code=status.HTTP_201_CREATED,
)
def rate_driver_for_ride(
    ride_id: int,
    rating_data: DriverRatingCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ride = (
        db.query(Ride)
        .filter(Ride.id == ride_id)
        .first()
    )

    if not ride:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ride not found",
        )

    if ride.passenger_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only the passenger who took this ride can rate the driver",
        )

    if ride.status != "completed":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only completed rides can be rated",
        )

    if ride.driver_id is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This ride has no assigned driver to rate",
        )

    existing_rating = (
        db.query(DriverRating)
        .filter(DriverRating.ride_id == ride.id)
        .first()
    )

    if existing_rating:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This ride has already been rated",
        )

    comment = (
        rating_data.comment.strip()
        if rating_data.comment
        else None
    )

    new_rating = DriverRating(
        ride_id=ride.id,
        passenger_id=current_user.id,
        driver_id=ride.driver_id,
        rating=rating_data.rating,
        comment=comment or None,
    )

    db.add(new_rating)
    db.commit()
    db.refresh(new_rating)

    return new_rating


@router.get(
    "/{ride_id}/rating",
    response_model=DriverRatingResponse,
)
def get_ride_rating(
    ride_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ride = (
        db.query(Ride)
        .filter(Ride.id == ride_id)
        .first()
    )

    if not ride:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ride not found",
        )

    driver = (
        db.query(Driver)
        .filter(Driver.user_id == current_user.id)
        .first()
    )

    is_passenger = ride.passenger_id == current_user.id
    is_driver = driver is not None and ride.driver_id == driver.id

    if not is_passenger and not is_driver:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You are not authorized to view this rating",
        )

    rating = (
        db.query(DriverRating)
        .filter(DriverRating.ride_id == ride.id)
        .first()
    )

    if not rating:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Rating not found",
        )

    return rating
