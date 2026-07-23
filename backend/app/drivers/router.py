from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.database.connection import get_db

from app.users.models import User

from app.drivers.models import Driver
from app.drivers.schemas import (
    DriverRegister,
    DriverResponse,
    DriverStatusUpdate,
)

from app.drivers.location_models import DriverLocation
from app.drivers.location_schemas import (
    DriverLocationUpdate,
    DriverLocationResponse,
)

from app.rides.models import Ride

from app.notifications.websocket_manager import manager


router = APIRouter(
    prefix="/drivers",
    tags=["Drivers"],
)


# ============================================================
# REGISTER DRIVER
# ============================================================

@router.post(
    "/register",
    response_model=DriverResponse,
    status_code=status.HTTP_201_CREATED,
)
def register_driver(
    driver_data: DriverRegister,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # --------------------------------------------------------
    # Only passengers/users can register as drivers
    # --------------------------------------------------------

    existing_driver = (
        db.query(Driver)
        .filter(
            Driver.user_id == current_user.id
        )
        .first()
    )

    if existing_driver:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You are already registered as a driver",
        )

    # --------------------------------------------------------
    # Check license number
    # --------------------------------------------------------

    existing_license = (
        db.query(Driver)
        .filter(
            Driver.license_number
            == driver_data.license_number
        )
        .first()
    )

    if existing_license:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="License number is already registered",
        )

    # --------------------------------------------------------
    # Create driver profile
    # --------------------------------------------------------

    new_driver = Driver(
        user_id=current_user.id,
        license_number=driver_data.license_number,
        is_verified=False,
        is_online=False,
    )

    db.add(new_driver)
    db.commit()
    db.refresh(new_driver)

    return new_driver


# ============================================================
# GET MY DRIVER PROFILE
# ============================================================

@router.get(
    "/me",
    response_model=DriverResponse,
)
def get_my_driver_profile(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Get the driver profile belonging to the
    currently authenticated user.

    IMPORTANT:

    current_user.id = User.id

    driver.id = Driver.id

    They are NOT the same ID.
    """

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
            detail="Driver profile not found. Please register as a driver first.",
        )

    return driver


# ============================================================
# UPDATE DRIVER ONLINE / OFFLINE STATUS
# ============================================================

@router.patch(
    "/status",
    response_model=DriverResponse,
)
def update_driver_status(
    status_data: DriverStatusUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # --------------------------------------------------------
    # Find driver profile using User.id
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
            detail="Driver profile not found. Please register as a driver first.",
        )

    # --------------------------------------------------------
    # Driver must be verified before going online
    # --------------------------------------------------------

    if (
        status_data.is_online
        and not driver.is_verified
    ):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=(
                "Driver must be verified "
                "before going online"
            ),
        )

    # --------------------------------------------------------
    # Update online status
    # --------------------------------------------------------

    driver.is_online = status_data.is_online

    db.commit()
    db.refresh(driver)

    return driver


# ============================================================
# UPDATE DRIVER LOCATION
# ============================================================

@router.patch(
    "/location",
    response_model=DriverLocationResponse,
)
async def update_driver_location(
    location_data: DriverLocationUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # --------------------------------------------------------
    # Find Driver profile using User.id
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
            detail="Driver profile not found. Please register as a driver first.",
        )

    # --------------------------------------------------------
    # Driver must be verified
    # --------------------------------------------------------

    if not driver.is_verified:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Driver is not verified",
        )

    # --------------------------------------------------------
    # Driver must be online
    # --------------------------------------------------------

    if not driver.is_online:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Driver is offline",
        )

    # --------------------------------------------------------
    # Find existing location
    #
    # DriverLocation.driver_id = Driver.id
    # NOT User.id
    # --------------------------------------------------------

    location = (
        db.query(DriverLocation)
        .filter(
            DriverLocation.driver_id == driver.id
        )
        .first()
    )

    # --------------------------------------------------------
    # Update existing location
    # --------------------------------------------------------

    if location:

        location.latitude = (
            location_data.latitude
        )

        location.longitude = (
            location_data.longitude
        )

        location.updated_at = (
            datetime.now(timezone.utc)
        )

    # --------------------------------------------------------
    # Create new location
    # --------------------------------------------------------

    else:

        location = DriverLocation(
            driver_id=driver.id,
            latitude=location_data.latitude,
            longitude=location_data.longitude,
        )

        db.add(location)

    db.commit()
    db.refresh(location)

    # ========================================================
    # FIND DRIVER'S ACTIVE RIDE
    # ========================================================

    active_ride = (
        db.query(Ride)
        .filter(
            Ride.driver_id == driver.id,
            Ride.status.in_(
                [
                    "assigned",
                    "accepted",
                    "driver_arriving",
                    "driver_arrived",
                    "in_progress",
                ]
            ),
        )
        .order_by(
            Ride.requested_at.desc()
        )
        .first()
    )

    # ========================================================
    # SEND LOCATION TO PASSENGER
    # ========================================================

    if active_ride:

        await manager.send_to_user(
            active_ride.passenger_id,
            {
                "type": "driver_location_update",

                "ride_id": active_ride.id,

                "driver_id": driver.id,

                "latitude": location.latitude,

                "longitude": location.longitude,
            },
        )

    return location


# ============================================================
# GET DRIVER LOCATION
# ============================================================

@router.get(
    "/{driver_id}/location",
    response_model=DriverLocationResponse,
)
def get_driver_location(
    driver_id: int,
    db: Session = Depends(get_db),
):
    location = (
        db.query(DriverLocation)
        .filter(
            DriverLocation.driver_id == driver_id
        )
        .first()
    )

    if not location:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Driver location not available",
        )

    return location