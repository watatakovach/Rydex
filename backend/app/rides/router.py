from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.database.connection import get_db
from app.drivers.models import Driver
from app.rides.models import Ride
from app.rides.schemas import RideCreate, RideResponse, RideStatusUpdate
from app.users.models import User


router = APIRouter(prefix="/rides", tags=["Rides"])

VALID_STATUSES = {
    "requested", "accepted", "driver_arriving", "driver_arrived",
    "in_progress", "completed", "cancelled"
}


def driver_for_user(db: Session, user: User):
    driver = db.query(Driver).filter(Driver.user_id == user.id).first()
    if not driver:
        raise HTTPException(404, "Driver profile not found")
    return driver


@router.post("", response_model=RideResponse, status_code=201)
@router.post("/", response_model=RideResponse, status_code=201)
def request_ride(
    data: RideCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if current_user.role != "passenger":
        raise HTTPException(403, "Only passengers can request rides")

    ride = Ride(
        passenger_id=current_user.id,
        pickup_address=data.pickup_address,
        destination_address=data.destination_address,
        pickup_latitude=data.pickup_latitude,
        pickup_longitude=data.pickup_longitude,
        destination_latitude=data.destination_latitude,
        destination_longitude=data.destination_longitude,
        status="requested",
    )
    db.add(ride)
    db.commit()
    db.refresh(ride)
    return ride


@router.get("/available", response_model=list[RideResponse])
def available_rides(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    driver = driver_for_user(db, current_user)
    if not driver.is_verified:
        raise HTTPException(403, "Driver account is not verified")
    return db.query(Ride).filter(Ride.status == "requested", Ride.driver_id.is_(None)).order_by(Ride.created_at.desc()).all()


@router.patch("/{ride_id}/accept", response_model=RideResponse)
def accept_ride(
    ride_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    driver = driver_for_user(db, current_user)
    if not driver.is_verified:
        raise HTTPException(403, "Driver account is not verified")

    ride = db.get(Ride, ride_id)
    if not ride:
        raise HTTPException(404, "Ride not found")
    if ride.driver_id is not None or ride.status != "requested":
        raise HTTPException(409, "Ride is no longer available")

    ride.driver_id = driver.id
    ride.status = "accepted"
    db.commit()
    db.refresh(ride)
    return ride


@router.patch("/{ride_id}/status", response_model=RideResponse)
def update_ride_status(
    ride_id: int,
    data: RideStatusUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if data.status not in VALID_STATUSES:
        raise HTTPException(400, "Invalid ride status")

    ride = db.get(Ride, ride_id)
    if not ride:
        raise HTTPException(404, "Ride not found")

    driver = db.query(Driver).filter(Driver.user_id == current_user.id).first()

    allowed = (
        ride.passenger_id == current_user.id
        or (driver and ride.driver_id == driver.id)
        or current_user.role == "admin"
    )
    if not allowed:
        raise HTTPException(403, "You cannot modify this ride")

    ride.status = data.status
    db.commit()
    db.refresh(ride)
    return ride


@router.get("/current", response_model=RideResponse | None)
def passenger_current_ride(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    ride = db.query(Ride).filter(
        Ride.passenger_id == current_user.id,
        Ride.status.in_(["requested", "accepted", "driver_arriving", "driver_arrived", "in_progress"]),
    ).order_by(Ride.created_at.desc()).first()
    return ride


@router.get("/my-rides", response_model=list[RideResponse])
def passenger_rides(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return db.query(Ride).filter(Ride.passenger_id == current_user.id).order_by(Ride.created_at.desc()).all()


@router.get("/driver/current", response_model=RideResponse | None)
def driver_current_ride(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    driver = driver_for_user(db, current_user)
    return db.query(Ride).filter(
        Ride.driver_id == driver.id,
        Ride.status.in_(["accepted", "driver_arriving", "driver_arrived", "in_progress"]),
    ).order_by(Ride.created_at.desc()).first()


@router.get("/driver/history", response_model=list[RideResponse])
def driver_history(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    driver = driver_for_user(db, current_user)
    return db.query(Ride).filter(Ride.driver_id == driver.id).order_by(Ride.created_at.desc()).all()
