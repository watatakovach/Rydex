from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.database.connection import get_db
from app.drivers.models import Driver
from app.users.models import User
from app.vehicles.models import Vehicle
from app.vehicles.schemas import VehicleRegister, VehicleResponse


router = APIRouter(
    prefix="/vehicles",
    tags=["Vehicles"],
)


@router.post(
    "/register",
    response_model=VehicleResponse,
    status_code=status.HTTP_201_CREATED,
)
def register_vehicle(
    vehicle_data: VehicleRegister,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # Find the driver's profile
    driver = (
        db.query(Driver)
        .filter(Driver.user_id == current_user.id)
        .first()
    )

    if not driver:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Driver profile not found. Register as a driver first.",
        )

    # Only verified drivers can register a vehicle
    if not driver.is_verified:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Your driver account must be verified before registering a vehicle.",
        )

    # Check license plate
    existing_vehicle = (
        db.query(Vehicle)
        .filter(
            Vehicle.license_plate
            == vehicle_data.license_plate
        )
        .first()
    )

    if existing_vehicle:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="License plate is already registered.",
        )

    # Create vehicle
    new_vehicle = Vehicle(
        driver_id=driver.id,
        make=vehicle_data.make,
        model=vehicle_data.model,
        year=vehicle_data.year,
        color=vehicle_data.color,
        license_plate=vehicle_data.license_plate,
    )

    db.add(new_vehicle)
    db.commit()
    db.refresh(new_vehicle)

    return new_vehicle