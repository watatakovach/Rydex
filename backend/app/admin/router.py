from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func, or_
from sqlalchemy.orm import Session

from app.auth.dependencies import (
    get_current_user,
    require_admin,
    require_super_admin,
)
from app.database.database import get_db

from app.admin.audit_models import AuditLog
from app.admin.audit_service import create_audit_log
from app.admin.schemas import *


from app.drivers.location_models import DriverLocation
from app.drivers.models import Driver

from app.notifications.models import Notification
from app.notifications.service import (
    create_notification as create_user_notification,
)

from app.ratings.models import DriverRating
from app.ratings.schemas import DriverRatingResponse

from app.rides.models import Ride

from app.settings.models.payment import PaymentSettings

from app.users.models import User

from app.wallet.transaction_models import WalletTransaction


# ============================================================
# ROUTER
# ============================================================

router = APIRouter(
    prefix="/admin",
    tags=["Admin"],
)


# ============================================================
# CONSTANTS
# ============================================================

ACTIVE_RIDE_STATUSES = (
    "accepted",
    "driver_arriving",
    "driver_arrived",
    "in_progress",
)


# ============================================================
# TIME HELPERS
# ============================================================

def now_utc() -> datetime:
    """Return the current UTC datetime."""
    return datetime.now(timezone.utc)


def day_start(value: datetime | None = None) -> datetime:
    """Return the start of the UTC day."""
    value = value or now_utc()

    return value.replace(
        hour=0,
        minute=0,
        second=0,
        microsecond=0,
    )


# ============================================================
# DATABASE HELPERS
# ============================================================

def get_user_or_404(
    db: Session,
    user_id: int,
) -> User:
    """Get a user or raise 404."""

    user = (
        db.query(User)
        .filter(User.id == user_id)
        .first()
    )

    if not user:
        raise HTTPException(
            status_code=404,
            detail="User not found.",
        )

    return user


def get_driver_with_user(
    db: Session,
    driver_id: int,
):
    """Return Driver + User for a valid driver account."""

    return (
        db.query(Driver, User)
        .join(
            User,
            Driver.user_id == User.id,
        )
        .filter(
            Driver.id == driver_id,
            User.role == "driver",
        )
        .first()
    )


def get_driver_or_404(
    db: Session,
    driver_id: int,
):
    """Get driver and associated user or raise 404."""

    result = get_driver_with_user(
        db,
        driver_id,
    )

    if not result:
        raise HTTPException(
            status_code=404,
            detail="Driver not found.",
        )

    return result


def get_ride_or_404(
    db: Session,
    ride_id: int,
) -> Ride:
    """Get ride or raise 404."""

    ride = (
        db.query(Ride)
        .filter(Ride.id == ride_id)
        .first()
    )

    if not ride:
        raise HTTPException(
            status_code=404,
            detail="Ride not found.",
        )

    return ride


def get_driver_location(
    db: Session,
    driver_id: int,
):
    """Return the driver's latest location."""

    return (
        db.query(DriverLocation)
        .filter(
            DriverLocation.driver_id == driver_id
        )
        .order_by(
            DriverLocation.updated_at.desc()
        )
        .first()
    )


# ============================================================
# PAYMENT / COMMISSION HELPERS
# ============================================================

def get_driver_commission_rate(
    db: Session,
) -> float:
    """
    Return driver commission as a decimal.

    Example:
        database value = 30.0
        returned value  = 0.30
    """

    settings = (
        db.query(PaymentSettings)
        .order_by(PaymentSettings.id.asc())
        .first()
    )

    if not settings:
        return 0.20

    percentage = (
        settings.driver_commission_percentage
    )

    if percentage is None:
        return 0.20

    return float(percentage) / 100.0


# ============================================================
# RATING HELPERS
# ============================================================

def rating_summary(
    db: Session,
    driver_id: int,
) -> dict[str, Any]:
    """Return driver's average rating and rating count."""

    average_rating, count = (
        db.query(
            func.avg(DriverRating.rating),
            func.count(DriverRating.id),
        )
        .filter(
            DriverRating.driver_id == driver_id
        )
        .first()
    )

    return {
        "average_rating": (
            round(float(average_rating), 2)
            if average_rating is not None
            else None
        ),
        "rating_count": int(count or 0),
    }


def driver_response(
    db: Session,
    driver: Driver,
    user: User,
):
    """Build the standard admin driver response."""

    return AdminDriverResponse(
        id=driver.id,
        user_id=driver.user_id,
        full_name=user.full_name,
        phone_number=user.phone_number,
        email=user.email,
        license_number=driver.license_number,
        driving_license_document=driver.driving_license_document,
        national_id_document=driver.national_id_document,
        vehicle_document=driver.vehicle_document,
        vehicle_make=driver.vehicle_make,
        vehicle_model=driver.vehicle_model,
        vehicle_color=driver.vehicle_color,
        vehicle_plate=driver.vehicle_plate,
        profile_photo=driver.profile_photo,
        vehicle_photo=driver.vehicle_photo,
        is_verified=driver.is_verified,
        is_online=driver.is_online,
        is_active=user.is_active,
        **rating_summary(db, driver.id),
    )


# ============================================================
# AUDIT HELPERS
# ============================================================

def audit(
    db: Session,
    admin: User,
    action: str,
    entity_type: str,
    entity_id: int | None,
    description: str,
    metadata: dict | None = None,
):
    """Create an admin audit log."""

    create_audit_log(
        db=db,
        admin_id=admin.id,
        action=action,
        entity_type=entity_type,
        entity_id=entity_id,
        description=description,
        metadata=metadata or {},
    )


def commit(
    db: Session,
    message: str,
):
    """Commit transaction safely."""

    try:
        db.commit()

    except Exception as exc:
        db.rollback()

        raise HTTPException(
            status_code=500,
            detail=message,
        ) from exc


# ============================================================
# DRIVER HELPERS
# ============================================================

def release_driver(
    db: Session,
    driver_id: int | None,
):
    """
    Release driver after ride completion/cancellation.
    """

    if driver_id is None:
        return

    result = get_driver_with_user(
        db,
        driver_id,
    )

    if not result:
        return

    driver, user = result

    driver.is_online = bool(
        driver.is_verified
        and user.is_active
    )


# ============================================================
# RATINGS
# ============================================================

@router.get("/ratings")
def ratings_summary(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    require_admin(current_user)

    average_rating, total = (
        db.query(
            func.avg(DriverRating.rating),
            func.count(DriverRating.id),
        )
        .first()
    )

    distribution = {
        str(star): (
            db.query(DriverRating)
            .filter(
                DriverRating.rating == star
            )
            .count()
        )
        for star in range(5, 0, -1)
    }

    return {
        "average_rating": (
            round(float(average_rating), 2)
            if average_rating is not None
            else 0
        ),
        "total_ratings": int(total or 0),
        "distribution": distribution,
    }


@router.get("/ratings/{driver_id}/summary")
def driver_rating_summary(
    driver_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    require_admin(current_user)

    db.query(Driver).filter(
        Driver.id == driver_id
    ).first() or (
        _ for _ in ()
    ).throw(
        HTTPException(
            status_code=404,
            detail="Driver not found.",
        )
    )

    summary = rating_summary(
        db,
        driver_id,
    )

    return {
        "driver_id": driver_id,
        "average_rating": summary["average_rating"] or 0,
        "total_ratings": summary["rating_count"],
    }


@router.get(
    "/ratings/{driver_id}",
    response_model=list[DriverRatingResponse],
)
def driver_ratings(
    driver_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    require_admin(current_user)

    get_driver_or_404(
        db,
        driver_id,
    )

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


# ============================================================
# DRIVERS
# ============================================================

@router.get(
    "/drivers/pending",
    response_model=list[PendingDriverResponse],
)
def pending_drivers(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    require_admin(current_user)

    return (
        db.query(Driver)
        .filter(
            Driver.is_verified.is_(False)
        )
        .order_by(
            Driver.id.desc()
        )
        .all()
    )


@router.patch(
    "/drivers/{driver_id}/verify",
    response_model=PendingDriverResponse,
)
def verify_driver(
    driver_id: int,
    verification: DriverVerification,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    require_admin(current_user)

    driver = (
        db.query(Driver)
        .filter(
            Driver.id == driver_id
        )
        .first()
    )

    if not driver:
        raise HTTPException(
            status_code=404,
            detail="Driver not found.",
        )

    driver.is_verified = verification.is_verified

    if not driver.is_verified:
        driver.is_online = False

    action = (
        "verify_driver"
        if driver.is_verified
        else "reject_driver"
    )

    audit(
        db,
        current_user,
        action,
        "driver",
        driver.id,
        "Driver verification updated by administrator.",
        {
            "is_verified": driver.is_verified,
        },
    )

    commit(
        db,
        "Could not update driver verification.",
    )

    return driver


@router.get(
    "/drivers",
    response_model=list[AdminDriverResponse],
)
def all_drivers(
    search: str | None = None,
    verified: bool | None = None,
    online: bool | None = None,
    active: bool | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    require_admin(current_user)

    query = (
        db.query(Driver, User)
        .join(
            User,
            Driver.user_id == User.id,
        )
        .filter(
            User.role == "driver"
        )
    )

    if search:
        value = f"%{search.strip()}%"

        query = query.filter(
            or_(
                User.full_name.ilike(value),
                User.phone_number.ilike(value),
                User.email.ilike(value),
                Driver.license_number.ilike(value),
                Driver.vehicle_plate.ilike(value),
            )
        )

    if verified is not None:
        query = query.filter(
            Driver.is_verified.is_(verified)
        )

    if online is not None:
        query = query.filter(
            Driver.is_online.is_(online)
        )

    if active is not None:
        query = query.filter(
            User.is_active.is_(active)
        )

    drivers = (
        query
        .order_by(Driver.id.desc())
        .all()
    )

    return [
        driver_response(
            db,
            driver,
            user,
        )
        for driver, user in drivers
    ]


@router.get(
    "/drivers/{driver_id}",
    response_model=AdminDriverDetailResponse,
)
def driver_details(
    driver_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    require_admin(current_user)

    driver, user = get_driver_or_404(
        db,
        driver_id,
    )

    return AdminDriverDetailResponse(
        id=driver.id,
        user_id=driver.user_id,
        full_name=user.full_name,
        phone_number=user.phone_number,
        email=user.email,
        role=user.role,
        is_active=user.is_active,
        is_verified=driver.is_verified,
        is_online=driver.is_online,
        profile_photo=driver.profile_photo,
        license_number=driver.license_number,
        vehicle_make=driver.vehicle_make,
        vehicle_model=driver.vehicle_model,
        vehicle_color=driver.vehicle_color,
        vehicle_plate=driver.vehicle_plate,
        vehicle_photo=driver.vehicle_photo,
        driving_license_document=driver.driving_license_document,
        national_id_document=driver.national_id_document,
        vehicle_document=driver.vehicle_document,
        created_at=user.created_at,
        **rating_summary(db, driver.id),
    )


@router.patch(
    "/drivers/{driver_id}/status",
    response_model=AdminDriverResponse,
)
def driver_status(
    driver_id: int,
    status_update: DriverStatusUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    require_admin(current_user)

    driver, user = get_driver_or_404(
        db,
        driver_id,
    )

    user.is_active = status_update.is_active

    if not user.is_active:
        driver.is_online = False

    action = (
        "activate_driver"
        if user.is_active
        else "suspend_driver"
    )

    audit(
        db,
        current_user,
        action,
        "driver",
        driver.id,
        "Driver account status updated by administrator.",
        {
            "is_active": user.is_active,
        },
    )

    commit(
        db,
        "Could not update driver status.",
    )

    db.refresh(driver)
    db.refresh(user)

    return driver_response(
        db,
        driver,
        user,
    )


@router.post(
    "/drivers",
    response_model=AdminDriverResponse,
    status_code=201,
)
def create_driver(
    data: AdminCreateDriver,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    require_admin(current_user)

    user = get_user_or_404(
        db,
        data.user_id,
    )

    if user.role in (
        "admin",
        "super_admin",
    ):
        raise HTTPException(
            status_code=400,
            detail="An administrator account cannot be converted into a driver.",
        )

    existing_driver = (
        db.query(Driver)
        .filter(
            Driver.user_id == user.id
        )
        .first()
    )

    if existing_driver:
        raise HTTPException(
            status_code=400,
            detail="This user is already registered as a driver.",
        )

    existing_license = (
        db.query(Driver)
        .filter(
            Driver.license_number
            == data.license_number
        )
        .first()
    )

    if existing_license:
        raise HTTPException(
            status_code=400,
            detail="License number is already registered.",
        )

    user.role = "driver"

    driver = Driver(
        user_id=user.id,
        license_number=data.license_number,
        is_verified=False,
        is_online=False,
    )

    db.add(driver)
    db.flush()

    audit(
        db,
        current_user,
        "create_driver",
        "driver",
        driver.id,
        "Driver profile created by administrator.",
        {
            "user_id": user.id,
        },
    )

    commit(
        db,
        "Could not create driver.",
    )

    db.refresh(driver)
    db.refresh(user)

    return driver_response(
        db,
        driver,
        user,
    )


@router.get(
    "/drivers/{driver_id}/performance",
    response_model=DriverPerformanceResponse,
)
def driver_performance(
    driver_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    require_admin(current_user)

    driver, user = get_driver_or_404(
        db,
        driver_id,
    )

    rides = (
        db.query(Ride)
        .filter(
            Ride.driver_id == driver.id
        )
        .all()
    )

    total = len(rides)

    completed = sum(
        ride.status == "completed"
        for ride in rides
    )

    cancelled = sum(
        ride.status == "cancelled"
        for ride in rides
    )

    active = sum(
        ride.status in ACTIVE_RIDE_STATUSES
        for ride in rides
    )

    earnings = sum(
        (ride.final_fare or 0)
        for ride in rides
        if ride.status == "completed"
    )

    return DriverPerformanceResponse(
        driver_id=driver.id,
        full_name=user.full_name,
        total_rides=total,
        completed_rides=completed,
        cancelled_rides=cancelled,
        active_rides=active,
        completion_rate=(
            round(
                completed / total * 100,
                2,
            )
            if total
            else 0
        ),
        total_earnings=round(
            earnings,
            2,
        ),
        average_fare=(
            round(
                earnings / completed,
                2,
            )
            if completed
            else 0
        ),
        is_online=driver.is_online,
        is_verified=driver.is_verified,
    )


@router.get(
    "/drivers/{driver_id}/earnings",
    response_model=DriverEarningsResponse,
)
def driver_earnings(
    driver_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    require_admin(current_user)

    driver, _ = get_driver_or_404(
        db,
        driver_id,
    )

    now = now_utc()
    today = day_start(now)
    week = today - timedelta(
        days=today.weekday()
    )
    month = today.replace(day=1)

    rides = (
        db.query(Ride)
        .filter(
            Ride.driver_id == driver.id,
            Ride.status == "completed",
        )
        .all()
    )

    def total_since(
        start: datetime,
    ) -> float:
        return sum(
            (ride.final_fare or 0)
            for ride in rides
            if ride.completed_at
            and ride.completed_at >= start
        )

    lifetime = sum(
        (ride.final_fare or 0)
        for ride in rides
    )

    return DriverEarningsResponse(
        today=round(
            total_since(today),
            2,
        ),
        this_week=round(
            total_since(week),
            2,
        ),
        this_month=round(
            total_since(month),
            2,
        ),
        lifetime=round(
            lifetime,
            2,
        ),
        completed_rides=len(rides),
    )


# ============================================================
# RIDES
# ============================================================

@router.get(
    "/rides",
    response_model=list[AdminRideResponse],
)
def all_rides(
    status_filter: str | None = Query(
        None,
        alias="status",
    ),
    passenger_id: int | None = None,
    driver_id: int | None = None,
    limit: int = Query(
        100,
        ge=1,
        le=500,
    ),
    offset: int = Query(
        0,
        ge=0,
    ),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    require_admin(current_user)

    query = db.query(Ride)

    if status_filter:
        query = query.filter(
            Ride.status == status_filter
        )

    if passenger_id is not None:
        query = query.filter(
            Ride.passenger_id == passenger_id
        )

    if driver_id is not None:
        query = query.filter(
            Ride.driver_id == driver_id
        )

    rides = (
        query
        .order_by(
            Ride.requested_at.desc()
        )
        .offset(offset)
        .limit(limit)
        .all()
    )

    result = []

    for ride in rides:
        passenger = (
            db.query(User)
            .filter(
                User.id == ride.passenger_id
            )
            .first()
        )

        if not passenger:
            continue

        driver_name = None
        driver_phone = None
        latitude = None
        longitude = None
        location_updated_at = None

        if ride.driver_id:
            pair = get_driver_with_user(
                db,
                ride.driver_id,
            )

            if pair:
                driver, driver_user = pair

                driver_name = driver_user.full_name
                driver_phone = driver_user.phone_number

                location = get_driver_location(
                    db,
                    driver.id,
                )

                if location:
                    latitude = location.latitude
                    longitude = location.longitude
                    location_updated_at = location.updated_at

        result.append(
            AdminRideResponse(
                id=ride.id,
                passenger_id=ride.passenger_id,
                driver_id=ride.driver_id,
                passenger_name=passenger.full_name,
                passenger_phone=passenger.phone_number,
                driver_name=driver_name,
                driver_phone=driver_phone,
                pickup_location=None,
                destination=None,
                pickup_latitude=ride.pickup_latitude,
                pickup_longitude=ride.pickup_longitude,
                destination_latitude=ride.destination_latitude,
                destination_longitude=ride.destination_longitude,
                driver_latitude=latitude,
                driver_longitude=longitude,
                driver_location_updated_at=location_updated_at,
                status=ride.status,
                estimated_fare=ride.estimated_fare,
                final_fare=ride.final_fare,
                distance_km=ride.distance_km,
                duration_minutes=ride.duration_minutes,
                requested_at=ride.requested_at,
                accepted_at=ride.accepted_at,
                started_at=ride.started_at,
                completed_at=ride.completed_at,
                cancelled_at=ride.cancelled_at,
                cancellation_reason=ride.cancellation_reason,
                cancelled_by=ride.cancelled_by,
                admin_note=ride.admin_note,
                admin_action=ride.admin_action,
                admin_id=ride.admin_id,
                admin_action_at=ride.admin_action_at,
            )
        )

    return result


@router.get(
    "/rides/{ride_id}",
    response_model=RideDetailResponse,
)
def ride_details(
    ride_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    require_admin(current_user)

    ride = get_ride_or_404(
        db,
        ride_id,
    )

    passenger = get_user_or_404(
        db,
        ride.passenger_id,
    )

    driver_name = None
    driver_phone = None
    latitude = None
    longitude = None
    location_updated_at = None

    if ride.driver_id:
        pair = get_driver_with_user(
            db,
            ride.driver_id,
        )

        if pair:
            driver, driver_user = pair

            driver_name = driver_user.full_name
            driver_phone = driver_user.phone_number

            location = get_driver_location(
                db,
                driver.id,
            )

            if location:
                latitude = location.latitude
                longitude = location.longitude
                location_updated_at = location.updated_at

    return RideDetailResponse(
        id=ride.id,
        passenger_name=passenger.full_name,
        passenger_phone=passenger.phone_number,
        driver_name=driver_name,
        driver_phone=driver_phone,
        pickup_location=None,
        destination=None,
        pickup_latitude=ride.pickup_latitude,
        pickup_longitude=ride.pickup_longitude,
        destination_latitude=ride.destination_latitude,
        destination_longitude=ride.destination_longitude,
        driver_latitude=latitude,
        driver_longitude=longitude,
        driver_location_updated_at=location_updated_at,
        status=ride.status,
        estimated_fare=ride.estimated_fare,
        final_fare=ride.final_fare,
        distance_km=ride.distance_km,
        duration_minutes=ride.duration_minutes,
        requested_at=ride.requested_at,
        accepted_at=ride.accepted_at,
        started_at=ride.started_at,
        completed_at=ride.completed_at,
        cancelled_at=ride.cancelled_at,
        cancellation_reason=ride.cancellation_reason,
        cancelled_by=ride.cancelled_by,
        admin_note=ride.admin_note,
        admin_action=ride.admin_action,
        admin_id=ride.admin_id,
        admin_action_at=ride.admin_action_at,
    )


@router.patch(
    "/rides/{ride_id}/cancel",
    response_model=RideActionResponse,
)
def cancel_ride(
    ride_id: int,
    request: RideActionRequest | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    require_admin(current_user)

    ride = get_ride_or_404(
        db,
        ride_id,
    )

    if ride.status in (
        "completed",
        "cancelled",
    ):
        raise HTTPException(
            status_code=400,
            detail="Ride cannot be cancelled.",
        )

    reason = (
        request.reason.strip()
        if request and request.reason
        else "Ride cancelled by administrator."
    )

    timestamp = now_utc()

    ride.status = "cancelled"
    ride.cancelled_at = timestamp
    ride.cancellation_reason = reason
    ride.cancelled_by = "admin"

    ride.admin_note = reason
    ride.admin_action = "cancel_ride"
    ride.admin_id = current_user.id
    ride.admin_action_at = timestamp

    audit(
        db,
        current_user,
        "cancel_ride",
        "ride",
        ride.id,
        "Ride cancelled by administrator.",
        {
            "reason": reason,
            "driver_id": ride.driver_id,
        },
    )

    release_driver(
        db,
        ride.driver_id,
    )

    commit(
        db,
        "Could not cancel ride.",
    )

    return RideActionResponse(
        message="Ride cancelled successfully.",
        ride_id=ride.id,
        status=ride.status,
    )


@router.patch(
    "/rides/{ride_id}/complete",
    response_model=RideActionResponse,
)
def complete_ride(
    ride_id: int,
    request: RideActionRequest | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    require_admin(current_user)

    ride = get_ride_or_404(
        db,
        ride_id,
    )

    if ride.status == "completed":
        raise HTTPException(
            status_code=400,
            detail="Ride already completed.",
        )

    if ride.status == "cancelled":
        raise HTTPException(
            status_code=400,
            detail="A cancelled ride cannot be completed.",
        )

    timestamp = now_utc()

    ride.status = "completed"
    ride.completed_at = (
        ride.completed_at or timestamp
    )

    if ride.final_fare is None:
        ride.final_fare = ride.estimated_fare

    ride.admin_note = (
        request.reason.strip()
        if request and request.reason
        else "Ride completed by administrator."
    )

    ride.admin_action = "complete_ride"
    ride.admin_id = current_user.id
    ride.admin_action_at = timestamp

    audit(
        db,
        current_user,
        "complete_ride",
        "ride",
        ride.id,
        "Ride completed by administrator.",
        {
            "driver_id": ride.driver_id,
            "final_fare": ride.final_fare,
        },
    )

    release_driver(
        db,
        ride.driver_id,
    )

    commit(
        db,
        "Could not complete ride.",
    )

    return RideActionResponse(
        message="Ride completed successfully.",
        ride_id=ride.id,
        status=ride.status,
    )


# ============================================================
# DASHBOARD
# ============================================================

@router.get(
    "/dashboard/stats",
    response_model=AdminDashboardStats,
)
def dashboard_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    require_admin(current_user)

    today = day_start()

    average_rating, rating_count = (
        db.query(
            func.avg(DriverRating.rating),
            func.count(DriverRating.id),
        )
        .first()
    )

    total_users = (
        db.query(User)
        .filter(
            User.role == "passenger"
        )
        .count()
    )

    total_drivers = (
        db.query(Driver)
        .count()
    )

    verified_drivers = (
        db.query(Driver)
        .filter(
            Driver.is_verified.is_(True)
        )
        .count()
    )

    pending_drivers = (
        total_drivers
        - verified_drivers
    )

    online_drivers = (
        db.query(Driver)
        .join(
            User,
            Driver.user_id == User.id,
        )
        .filter(
            Driver.is_verified.is_(True),
            Driver.is_online.is_(True),
            User.is_active.is_(True),
        )
        .count()
    )

    total_rides = (
        db.query(Ride)
        .count()
    )

    active_rides = (
        db.query(Ride)
        .filter(
            Ride.status.in_(
                ACTIVE_RIDE_STATUSES
            )
        )
        .count()
    )

    completed_rides = (
        db.query(Ride)
        .filter(
            Ride.status == "completed"
        )
        .count()
    )

    cancelled_rides = (
        db.query(Ride)
        .filter(
            Ride.status == "cancelled"
        )
        .count()
    )

    total_revenue = float(
        db.query(
            func.coalesce(
                func.sum(Ride.final_fare),
                0,
            )
        )
        .filter(
            Ride.status == "completed"
        )
        .scalar()
        or 0
    )

    todays_revenue = float(
        db.query(
            func.coalesce(
                func.sum(Ride.final_fare),
                0,
            )
        )
        .filter(
            Ride.status == "completed",
            Ride.completed_at >= today,
        )
        .scalar()
        or 0
    )

    # IMPORTANT:
    # Commission now comes from PaymentSettings,
    # not from a hard-coded 20% constant.
    platform_commission_percentage = (
        get_driver_commission_rate(db)
    )

    platform_commission = (
        todays_revenue
        * platform_commission_percentage / 100
    )

    driver_earnings = (
        todays_revenue
        - platform_commission
    )

    average_fare = (
        total_revenue / completed_rides
        if completed_rides
        else 0
    )

    average_distance = float(
        db.query(
            func.avg(Ride.distance_km)
        )
        .filter(
            Ride.status == "completed",
            Ride.distance_km.isnot(None),
        )
        .scalar()
        or 0
    )

    average_duration = float(
        db.query(
            func.avg(
                Ride.duration_minutes
            )
        )
        .filter(
            Ride.status == "completed",
            Ride.duration_minutes.isnot(None),
        )
        .scalar()
        or 0
    )

    registrations = (
        db.query(User)
        .filter(
            User.created_at >= today
        )
        .count()
    )

    completion_rate = (
        completed_rides
        / total_rides
        * 100
        if total_rides
        else 0
    )

    return AdminDashboardStats(
        total_users=total_users,
        total_drivers=total_drivers,
        verified_drivers=verified_drivers,
        pending_driver_verifications=pending_drivers,
        online_drivers=online_drivers,
        total_rides=total_rides,
        active_rides=active_rides,
        completed_rides=completed_rides,
        cancelled_rides=cancelled_rides,
        todays_revenue=round(
            todays_revenue,
            2,
        ),
        total_revenue=round(
            total_revenue,
            2,
        ),
        driver_earnings=round(
            driver_earnings,
            2,
        ),
        platform_commission=round(
            platform_commission,
            2,
        ),
        average_ride_fare=round(
            average_fare,
            2,
        ),
        average_ride_distance=round(
            average_distance,
            2,
        ),
        average_ride_duration=round(
            average_duration,
            2,
        ),
        new_registrations=registrations,
        completion_rate=round(
            completion_rate,
            2,
        ),
        average_rating=(
            round(
                float(average_rating),
                2,
            )
            if average_rating is not None
            else 0
        ),
        total_ratings=int(
            rating_count or 0
        ),
    )


@router.get(
    "/dashboard/analytics",
    response_model=AdminDashboardAnalytics,
)
def dashboard_analytics(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    require_admin(current_user)

    today = day_start()

    rides_over_time = []
    growth = []

    for days_ago in range(6, -1, -1):
        start = today - timedelta(
            days=days_ago
        )

        end = start + timedelta(
            days=1
        )

        ride_query = (
            db.query(Ride)
            .filter(
                Ride.requested_at >= start,
                Ride.requested_at < end,
            )
        )

        ride_count = ride_query.count()

        revenue = float(
            ride_query
            .filter(
                Ride.status == "completed"
            )
            .with_entities(
                func.coalesce(
                    func.sum(
                        Ride.final_fare
                    ),
                    0,
                )
            )
            .scalar()
            or 0
        )

        rides_over_time.append(
            AnalyticsDataPoint(
                date=start.strftime(
                    "%Y-%m-%d"
                ),
                rides=ride_count,
                revenue=round(
                    revenue,
                    2,
                ),
            )
        )

        growth.append(
            UserGrowthAnalytics(
                date=start.strftime(
                    "%Y-%m-%d"
                ),
                passengers=(
                    db.query(User)
                    .filter(
                        User.role == "passenger",
                        User.created_at >= start,
                        User.created_at < end,
                    )
                    .count()
                ),
                drivers=(
                    db.query(User)
                    .filter(
                        User.role == "driver",
                        User.created_at >= start,
                        User.created_at < end,
                    )
                    .count()
                ),
            )
        )

    return AdminDashboardAnalytics(
        rides_over_time=rides_over_time,
        ride_status=RideStatusAnalytics(
            completed=(
                db.query(Ride)
                .filter(
                    Ride.status == "completed"
                )
                .count()
            ),
            cancelled=(
                db.query(Ride)
                .filter(
                    Ride.status == "cancelled"
                )
                .count()
            ),
            active=(
                db.query(Ride)
                .filter(
                    Ride.status.in_(
                        ACTIVE_RIDE_STATUSES
                    )
                )
                .count()
            ),
        ),
        user_growth=growth,
    )


# ============================================================
# USERS
# ============================================================

@router.get(
    "/passengers",
    response_model=list[AdminUserResponse],
)
def passengers(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    require_admin(current_user)

    return (
        db.query(User)
        .filter(
            User.role == "passenger"
        )
        .order_by(
            User.id.desc()
        )
        .all()
    )


@router.get(
    "/users",
    response_model=list[AdminUserListResponse],
)
def users(
    search: str | None = None,
    status_filter: str | None = None,
    role: str | None = None,
    new_users: bool = False,
    limit: int = Query(
        100,
        ge=1,
        le=500,
    ),
    offset: int = Query(
        0,
        ge=0,
    ),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    require_admin(current_user)

    query = db.query(User)

    if search:
        value = f"%{search.strip()}%"

        query = query.filter(
            or_(
                User.full_name.ilike(value),
                User.phone_number.ilike(value),
                User.email.ilike(value),
            )
        )

    if status_filter == "active":
        query = query.filter(
            User.is_active.is_(True)
        )

    elif status_filter == "suspended":
        query = query.filter(
            User.is_active.is_(False)
        )

    elif status_filter:
        raise HTTPException(
            status_code=400,
            detail="Invalid status_filter.",
        )

    if role:
        allowed_roles = {
            "passenger",
            "driver",
            "admin",
            "super_admin",
        }

        if role not in allowed_roles:
            raise HTTPException(
                status_code=400,
                detail="Invalid user role.",
            )

        query = query.filter(
            User.role == role
        )

    if new_users:
        query = query.filter(
            User.created_at
            >= now_utc() - timedelta(days=7)
        )

    return (
        query
        .order_by(
            User.created_at.desc()
        )
        .offset(offset)
        .limit(limit)
        .all()
    )


@router.get(
    "/users/{user_id}",
    response_model=AdminUserDetailResponse,
)
def user_details(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    require_admin(current_user)

    return get_user_or_404(
        db,
        user_id,
    )


@router.get(
    "/users/{user_id}/rides",
    response_model=list[AdminUserRideResponse],
)
def user_rides(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    require_admin(current_user)

    user = get_user_or_404(
        db,
        user_id,
    )

    if user.role == "passenger":
        return (
            db.query(Ride)
            .filter(
                Ride.passenger_id == user_id
            )
            .order_by(
                Ride.requested_at.desc()
            )
            .all()
        )

    if user.role == "driver":
        driver = (
            db.query(Driver)
            .filter(
                Driver.user_id == user_id
            )
            .first()
        )

        if not driver:
            return []

        return (
            db.query(Ride)
            .filter(
                Ride.driver_id == driver.id
            )
            .order_by(
                Ride.requested_at.desc()
            )
            .all()
        )

    return []


@router.get(
    "/users/{user_id}/cancellations",
    response_model=list[AdminUserCancellationResponse],
)
def user_cancellations(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    require_admin(current_user)

    user = get_user_or_404(
        db,
        user_id,
    )

    query = (
        db.query(Ride)
        .filter(
            Ride.status == "cancelled"
        )
    )

    if user.role == "passenger":
        query = query.filter(
            Ride.passenger_id == user_id
        )

    elif user.role == "driver":
        driver = (
            db.query(Driver)
            .filter(
                Driver.user_id == user_id
            )
            .first()
        )

        if not driver:
            return []

        query = query.filter(
            Ride.driver_id == driver.id
        )

    else:
        return []

    return (
        query
        .order_by(
            Ride.requested_at.desc()
        )
        .all()
    )


@router.get(
    "/users/{user_id}/payments",
    response_model=list[AdminDriverPaymentResponse],
)
def user_payments(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    require_admin(current_user)

    user = get_user_or_404(
        db,
        user_id,
    )

    if user.role != "driver":
        return []

    driver = (
        db.query(Driver)
        .filter(
            Driver.user_id == user.id
        )
        .first()
    )

    if not driver:
        return []

    return (
        db.query(WalletTransaction)
        .filter(
            WalletTransaction.driver_id
            == driver.id
        )
        .order_by(
            WalletTransaction.created_at.desc()
        )
        .all()
    )


@router.patch(
    "/users/{user_id}/status",
    response_model=AdminUserDetailResponse,
)
def user_status(
    user_id: int,
    data: AdminUserStatusUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    require_admin(current_user)

    user = get_user_or_404(
        db,
        user_id,
    )

    # Never allow an administrator to
    # disable their own account.
    if user.id == current_user.id:
        raise HTTPException(
            status_code=400,
            detail="You cannot change your own account status.",
        )

    user.is_active = data.is_active

    if (
        user.role == "driver"
        and not user.is_active
    ):
        driver = (
            db.query(Driver)
            .filter(
                Driver.user_id == user.id
            )
            .first()
        )

        if driver:
            driver.is_online = False

    action = (
        "activate_user"
        if user.is_active
        else "suspend_user"
    )

    audit(
        db,
        current_user,
        action,
        "user",
        user.id,
        "User account status updated by administrator.",
        {
            "role": user.role,
            "is_active": user.is_active,
        },
    )

    commit(
        db,
        "Could not update user status.",
    )

    db.refresh(user)

    return user


# ============================================================
# AUDIT LOGS
# ============================================================

@router.get(
    "/audit-logs",
    response_model=AuditLogListResponse,
)
def audit_logs(
    action: str | None = None,
    entity_type: str | None = None,
    admin_id: int | None = None,
    entity_id: int | None = None,
    limit: int = Query(
        100,
        ge=1,
        le=500,
    ),
    offset: int = Query(
        0,
        ge=0,
    ),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    require_admin(current_user)

    query = db.query(AuditLog)

    if action:
        query = query.filter(
            AuditLog.action == action
        )

    if entity_type:
        query = query.filter(
            AuditLog.entity_type == entity_type
        )

    if admin_id is not None:
        query = query.filter(
            AuditLog.admin_id == admin_id
        )

    if entity_id is not None:
        query = query.filter(
            AuditLog.entity_id == entity_id
        )

    total = query.count()

    logs = (
        query
        .order_by(
            AuditLog.created_at.desc()
        )
        .offset(offset)
        .limit(limit)
        .all()
    )

    return AuditLogListResponse(
        total=total,
        logs=logs,
    )


@router.get(
    "/audit-logs/{audit_log_id}",
    response_model=AuditLogResponse,
)
def audit_log(
    audit_log_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    require_admin(current_user)

    log = (
        db.query(AuditLog)
        .filter(
            AuditLog.id == audit_log_id
        )
        .first()
    )

    if not log:
        raise HTTPException(
            status_code=404,
            detail="Audit log not found.",
        )

    return log


# ============================================================
# NOTIFICATIONS
# ============================================================

@router.get(
    "/notifications",
    response_model=AdminNotificationListResponse,
)
def notifications(
    user_id: int | None = None,
    unread_only: bool = False,
    limit: int = Query(
        100,
        ge=1,
        le=500,
    ),
    offset: int = Query(
        0,
        ge=0,
    ),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    require_admin(current_user)

    query = db.query(Notification)

    if user_id is not None:
        query = query.filter(
            Notification.user_id == user_id
        )

    total = query.count()

    unread = (
        query
        .filter(
            Notification.is_read.is_(False)
        )
        .count()
    )

    if unread_only:
        query = query.filter(
            Notification.is_read.is_(False)
        )

    items = (
        query
        .order_by(
            Notification.created_at.desc()
        )
        .offset(offset)
        .limit(limit)
        .all()
    )

    return AdminNotificationListResponse(
        total=total,
        unread=unread,
        read=total - unread,
        notifications=items,
    )


@router.get(
    "/notifications/{notification_id}",
    response_model=AdminNotificationResponse,
)
def notification(
    notification_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    require_admin(current_user)

    notification_obj = (
        db.query(Notification)
        .filter(
            Notification.id == notification_id
        )
        .first()
    )

    if not notification_obj:
        raise HTTPException(
            status_code=404,
            detail="Notification not found.",
        )

    return notification_obj


@router.post(
    "/notifications",
    response_model=AdminNotificationResponse,
    status_code=201,
)
async def create_notification(
    data: AdminNotificationCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    require_admin(current_user)

    get_user_or_404(
        db,
        data.user_id,
    )

    notification_obj = (
        await create_user_notification(
            db=db,
            user_id=data.user_id,
            notification_type=data.type,
            title=data.title,
            message=data.message,
            entity_type=data.entity_type,
            entity_id=data.entity_id,
            data=data.data,
        )
    )

    audit(
        db,
        current_user,
        "create_notification",
        "notification",
        notification_obj.id,
        "Admin created a notification.",
        {
            "user_id": data.user_id,
            "type": data.type,
        },
    )

    commit(
        db,
        "Could not create notification.",
    )

    db.refresh(notification_obj)

    return notification_obj


@router.patch(
    "/notifications/{notification_id}/read",
    response_model=AdminNotificationActionResponse,
)
def mark_notification_read(
    notification_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    require_admin(current_user)

    notification_obj = (
        db.query(Notification)
        .filter(
            Notification.id == notification_id
        )
        .first()
    )

    if not notification_obj:
        raise HTTPException(
            status_code=404,
            detail="Notification not found.",
        )

    notification_obj.is_read = True

    commit(
        db,
        "Could not mark notification as read.",
    )

    return AdminNotificationActionResponse(
        message="Notification marked as read.",
        notification_id=notification_obj.id,
    )


@router.patch(
    "/notifications/read-all",
    response_model=AdminNotificationActionResponse,
)
def mark_all_notifications_read(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    require_admin(current_user)

    items = (
        db.query(Notification)
        .filter(
            Notification.is_read.is_(False)
        )
        .all()
    )

    for notification_obj in items:
        notification_obj.is_read = True

    commit(
        db,
        "Could not mark notifications as read.",
    )

    return AdminNotificationActionResponse(
        message="All notifications marked as read.",
        affected=len(items),
    )


@router.delete(
    "/notifications/{notification_id}",
    response_model=AdminNotificationActionResponse,
)
def delete_notification(
    notification_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    require_admin(current_user)

    notification_obj = (
        db.query(Notification)
        .filter(
            Notification.id == notification_id
        )
        .first()
    )

    if not notification_obj:
        raise HTTPException(
            status_code=404,
            detail="Notification not found.",
        )

    db.delete(notification_obj)

    audit(
        db,
        current_user,
        "delete_notification",
        "notification",
        notification_id,
        "Admin deleted a notification.",
    )

    commit(
        db,
        "Could not delete notification.",
    )

    return AdminNotificationActionResponse(
        message="Notification deleted successfully.",
        notification_id=notification_id,
    )


@router.post(
    "/notifications/broadcast"
)
async def broadcast(
    data: AdminNotificationBroadcast,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    require_admin(current_user)

    users = (
        db.query(User)
        .filter(
            User.is_active.is_(True)
        )
        .all()
    )

    created = 0

    try:
        for user in users:
            await create_user_notification(
                db=db,
                user_id=user.id,
                notification_type=data.type,
                title=data.title,
                message=data.message,
                entity_type=data.entity_type,
                entity_id=data.entity_id,
                data=data.data,
            )

            created += 1

        audit(
            db,
            current_user,
            "broadcast_notification",
            "notification",
            None,
            "Admin broadcast a notification.",
            {
                "affected_users": created,
                "type": data.type,
            },
        )

        db.commit()

    except Exception as exc:
        db.rollback()

        raise HTTPException(
            status_code=500,
            detail="Could not broadcast notification.",
        ) from exc

    return {
        "message": "Notification broadcast successfully.",
        "affected_users": created,
    }

