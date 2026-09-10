from sqlalchemy import func
from sqlalchemy.orm import Session

from fastapi import APIRouter, Depends, HTTPException, status

from app.auth.dependencies import get_current_user
from app.database.database import get_db
from app.drivers.models import Driver
from app.ratings.models import DriverRating
from app.ratings.schemas import (
    DriverRatingCreate,
    DriverRatingResponse,
)
from app.rides.models import Ride
from app.users.models import User

router = APIRouter(
    prefix="/ratings",
    tags=["Ratings"],
)


# ============================================================
# CREATE DRIVER RATING
# ============================================================

@router.post(
    "/rides/{ride_id}",
    response_model=DriverRatingResponse,
    status_code=status.HTTP_201_CREATED,
)
def rate_driver(
    ride_id: int,
    payload: DriverRatingCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):

    ride = (
        db.query(Ride)
        .filter(Ride.id == ride_id)
        .first()
    )

    if ride is None:
        raise HTTPException(
            status_code=404,
            detail="Ride not found",
        )

    if ride.passenger_id != current_user.id:
        raise HTTPException(
            status_code=403,
            detail="You cannot rate this ride.",
        )

    if ride.status != "completed":
        raise HTTPException(
            status_code=400,
            detail="Ride is not completed.",
        )

    if ride.driver_id is None:
        raise HTTPException(
            status_code=400,
            detail="Ride has no driver.",
        )

    existing = (
        db.query(DriverRating)
        .filter(
            DriverRating.ride_id == ride.id
        )
        .first()
    )

    if existing:
        raise HTTPException(
            status_code=400,
            detail="Ride already rated.",
        )

    rating = DriverRating(
        ride_id=ride.id,
        passenger_id=current_user.id,
        driver_id=ride.driver_id,
        rating=payload.rating,
        comment=payload.comment,
    )

    db.add(rating)
    db.commit()
    db.refresh(rating)

    return rating


# ============================================================
# GET RATING FOR A RIDE
# ============================================================

@router.get(
    "/rides/{ride_id}",
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

    if ride is None:
        raise HTTPException(
            status_code=404,
            detail="Ride not found.",
        )

    if (
        current_user.id != ride.passenger_id
        and current_user.role not in ["admin", "super_admin"]
    ):
        raise HTTPException(
            status_code=403,
            detail="Not allowed.",
        )

    rating = (
        db.query(DriverRating)
        .filter(
            DriverRating.ride_id == ride.id
        )
        .first()
    )

    if rating is None:
        raise HTTPException(
            status_code=404,
            detail="Rating not found.",
        )

    return rating


# ============================================================
# DRIVER RATINGS SUMMARY
# ============================================================

@router.get(
    "/drivers/me",
)
def my_ratings(
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

    if driver is None:
        raise HTTPException(
            status_code=404,
            detail="Driver not found.",
        )

    average = (
        db.query(
            func.avg(DriverRating.rating)
        )
        .filter(
            DriverRating.driver_id == driver.id
        )
        .scalar()
    )

    count = (
        db.query(DriverRating)
        .filter(
            DriverRating.driver_id == driver.id
        )
        .count()
    )

    reviews = (
        db.query(DriverRating)
        .filter(
            DriverRating.driver_id == driver.id
        )
        .order_by(
            DriverRating.created_at.desc()
        )
        .limit(10)
        .all()
    )

    return {
        "average_rating": round(float(average), 2) if average else 0,
        "rating_count": count,
        "reviews": reviews,
    }
    
@router.get("/drivers/{driver_id}/summary")
def driver_rating_summary(
    driver_id: int,
    db: Session = Depends(get_db),
):
    average = (
        db.query(func.avg(DriverRating.rating))
        .filter(DriverRating.driver_id == driver_id)
        .scalar()
    )

    count = (
        db.query(DriverRating)
        .filter(DriverRating.driver_id == driver_id)
        .count()
    )

    return {
        "average_rating": round(float(average), 2) if average else 0,
        "rating_count": count,
    }
    
@router.get("/drivers/{driver_id}/reviews")
def driver_reviews(
    driver_id: int,
    db: Session = Depends(get_db),
):

    return (
        db.query(DriverRating)
        .filter(
            DriverRating.driver_id == driver_id
        )
        .order_by(
            DriverRating.created_at.desc()
        )
        .all()
    )