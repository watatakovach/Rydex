from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.database.connection import get_db
from app.drivers.models import Driver
from app.drivers.schemas import DriverLocationUpdate, DriverRegister, DriverResponse, DriverStatusUpdate
from app.users.models import User


router = APIRouter(prefix="/drivers", tags=["Drivers"])


def get_driver(current_user: User, db: Session) -> Driver:
    driver = db.query(Driver).filter(Driver.user_id == current_user.id).first()
    if not driver:
        raise HTTPException(404, "Driver profile not found")
    return driver


@router.post("/register", response_model=DriverResponse, status_code=201)
def register_driver(
    data: DriverRegister,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if current_user.role not in ("passenger", "driver"):
        raise HTTPException(403, "This account cannot register as a driver")

    if db.query(Driver).filter(Driver.user_id == current_user.id).first():
        raise HTTPException(400, "Driver profile already exists")

    if db.query(Driver).filter(Driver.license_number == data.license_number).first():
        raise HTTPException(400, "License number is already registered")

    driver = Driver(user_id=current_user.id, license_number=data.license_number)
    current_user.role = "driver"
    db.add(driver)
    db.commit()
    db.refresh(driver)
    return driver


@router.get("/me", response_model=DriverResponse)
@router.get("/profile", response_model=DriverResponse)
def get_driver_profile(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return get_driver(current_user, db)


@router.patch("/status", response_model=DriverResponse)
def update_driver_status(
    data: DriverStatusUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    driver = get_driver(current_user, db)

    if data.is_online and not driver.is_verified:
        raise HTTPException(403, "Driver account is not verified")

    driver.is_online = data.is_online
    db.commit()
    db.refresh(driver)
    return driver


@router.patch("/location")
def update_driver_location(
    data: DriverLocationUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    driver = get_driver(current_user, db)
    driver.latitude = str(data.latitude)
    driver.longitude = str(data.longitude)
    db.commit()
    return {"driver_id": driver.id, "latitude": data.latitude, "longitude": data.longitude}


@router.get("/{driver_id}/location")
def get_driver_location(
    driver_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    driver = db.get(Driver, driver_id)
    if not driver:
        raise HTTPException(404, "Driver not found")
    return {"driver_id": driver.id, "latitude": driver.latitude, "longitude": driver.longitude}
