from __future__ import annotations

from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, or_
from sqlalchemy.orm import Session

from app.auth.dependencies import require_super_admin
from app.auth.security import hash_password
from app.database.database import get_db

from app.admin.audit_models import AuditLog

from app.drivers.models import Driver
from app.drivers.location_models import DriverLocation

from app.notifications.models import Notification

from app.rides.models import Ride

from app.ratings.models import DriverRating

from app.users.models import User

from app.wallet.transaction_models import WalletTransaction


# ============================================================
# ROUTER
# ============================================================

router = APIRouter(
    prefix="/super-admin",
    tags=["Super Admin"],
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

ALLOWED_ROLES = {
    "passenger",
    "driver",
    "admin",
}


# ============================================================
# TIME HELPERS
# ============================================================

def now_utc() -> datetime:
    return datetime.now(timezone.utc)


def day_start(value: datetime | None = None) -> datetime:
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


def get_admin_or_404(
    db: Session,
    admin_id: int,
) -> User:

    admin = (
        db.query(User)
        .filter(
            User.id == admin_id,
            User.role == "admin",
        )
        .first()
    )

    if not admin:
        raise HTTPException(
            status_code=404,
            detail="Admin account not found.",
        )

    return admin


def prevent_self_modification(
    current_user: User,
    target_user: User,
) -> None:

    if current_user.id == target_user.id:
        raise HTTPException(
            status_code=400,
            detail="You cannot modify your own account through this endpoint.",
        )


# ============================================================
# SUPER ADMIN PROFILE
# ============================================================

@router.get("/me")
def super_admin_me(
    current_user: User = Depends(require_super_admin),
):
    return {
        "id": current_user.id,
        "full_name": current_user.full_name,
        "email": current_user.email,
        "phone_number": current_user.phone_number,
        "role": current_user.role,
        "is_active": current_user.is_active,
    }


# ============================================================
# SUPER ADMIN DASHBOARD
# ============================================================

@router.get("/dashboard")
def super_admin_dashboard(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_super_admin),
):

    today = day_start()

    total_users = (
        db.query(User)
        .count()
    )

    total_passengers = (
        db.query(User)
        .filter(
            User.role == "passenger"
        )
        .count()
    )

    total_driver_users = (
        db.query(User)
        .filter(
            User.role == "driver"
        )
        .count()
    )

    total_admins = (
        db.query(User)
        .filter(
            User.role == "admin"
        )
        .count()
    )

    total_super_admins = (
        db.query(User)
        .filter(
            User.role == "super_admin"
        )
        .count()
    )

    active_users = (
        db.query(User)
        .filter(
            User.is_active.is_(True)
        )
        .count()
    )

    suspended_users = (
        db.query(User)
        .filter(
            User.is_active.is_(False)
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

    online_drivers = (
        db.query(Driver)
        .filter(
            Driver.is_online.is_(True)
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
            Ride.status.in_(ACTIVE_RIDE_STATUSES)
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

    requested_rides = (
        db.query(Ride)
        .filter(
            Ride.status == "requested"
        )
        .count()
    )

    todays_rides = (
        db.query(Ride)
        .filter(
            Ride.requested_at >= today
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
            Ride.requested_at >= today,
        )
        .scalar()
        or 0
    )

    new_users_today = (
        db.query(User)
        .filter(
            User.created_at >= today
        )
        .count()
    )

    pending_driver_verifications = (
        db.query(Driver)
        .filter(
            Driver.is_verified.is_(False)
        )
        .count()
    )

    average_rating = float(
        db.query(
            func.avg(DriverRating.rating)
        )
        .scalar()
        or 0
    )

    return {
        "users": {
            "total": total_users,
            "passengers": total_passengers,
            "drivers": total_driver_users,
            "admins": total_admins,
            "super_admins": total_super_admins,
            "active": active_users,
            "suspended": suspended_users,
            "new_today": new_users_today,
        },
        "drivers": {
            "total": total_drivers,
            "verified": verified_drivers,
            "online": online_drivers,
            "pending_verification": pending_driver_verifications,
        },
        "rides": {
            "total": total_rides,
            "requested": requested_rides,
            "active": active_rides,
            "completed": completed_rides,
            "cancelled": cancelled_rides,
            "today": todays_rides,
        },
        "revenue": {
            "total": round(total_revenue, 2),
            "today": round(todays_revenue, 2),
        },
        "ratings": {
            "average": round(average_rating, 2),
        },
        "system": {
            "generated_at": now_utc(),
        },
    }


# ============================================================
# SUPER ADMIN ANALYTICS
# ============================================================

@router.get("/analytics")
def super_admin_analytics(
    days: int = Query(
        7,
        ge=1,
        le=90,
    ),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_super_admin),
):
    today = day_start()

    rides_over_time = []
    user_growth = []
    revenue_over_time = []

    for days_ago in range(days - 1, -1, -1):
        start = today - timedelta(days=days_ago)
        end = start + timedelta(days=1)

        # ========================================================
        # RIDES REQUESTED ON THIS DAY
        # ========================================================

        ride_count = (
            db.query(Ride)
            .filter(
                Ride.requested_at >= start,
                Ride.requested_at < end,
            )
            .count()
        )

        # ========================================================
        # RIDES COMPLETED ON THIS DAY
        # Use completed_at, NOT requested_at
        # ========================================================

        completed = (
            db.query(Ride)
            .filter(
                Ride.status == "completed",
                Ride.completed_at.isnot(None),
                Ride.completed_at >= start,
                Ride.completed_at < end,
            )
            .count()
        )

        # ========================================================
        # REVENUE GENERATED ON THIS DAY
        # Use completed_at because revenue is realized
        # when the ride is completed.
        # ========================================================

        revenue = (
            db.query(
                func.coalesce(
                    func.sum(Ride.final_fare),
                    0,
                )
            )
            .filter(
                Ride.status == "completed",
                Ride.completed_at.isnot(None),
                Ride.completed_at >= start,
                Ride.completed_at < end,
            )
            .scalar()
            or 0
        )

        revenue = float(revenue)

        # ========================================================
        # NEW PASSENGERS
        # ========================================================

        passengers = (
            db.query(User)
            .filter(
                User.role == "passenger",
                User.created_at >= start,
                User.created_at < end,
            )
            .count()
        )

        # ========================================================
        # NEW DRIVERS
        # ========================================================

        drivers = (
            db.query(User)
            .filter(
                User.role == "driver",
                User.created_at >= start,
                User.created_at < end,
            )
            .count()
        )

        # ========================================================
        # RESPONSE DATA
        # ========================================================

        rides_over_time.append({
            "date": start.strftime("%Y-%m-%d"),
            "rides": ride_count,
            "completed": completed,
        })

        revenue_over_time.append({
            "date": start.strftime("%Y-%m-%d"),
            "revenue": round(revenue, 2),
        })

        user_growth.append({
            "date": start.strftime("%Y-%m-%d"),
            "passengers": passengers,
            "drivers": drivers,
        })

    return {
        "days": days,
        "rides_over_time": rides_over_time,
        "revenue_over_time": revenue_over_time,
        "user_growth": user_growth,
    }


# ============================================================
# ADMIN MANAGEMENT
# ============================================================

@router.get("/admins")
def list_admins(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_super_admin),
):

    admins = (
        db.query(User)
        .filter(
            User.role == "admin"
        )
        .order_by(
            User.id.desc()
        )
        .all()
    )

    return [
        {
            "id": admin.id,
            "full_name": admin.full_name,
            "phone_number": admin.phone_number,
            "email": admin.email,
            "role": admin.role,
            "is_active": admin.is_active,
            "created_at": admin.created_at,
        }
        for admin in admins
    ]


@router.post(
    "/admins",
    status_code=status.HTTP_201_CREATED,
)
def create_admin(
    full_name: str,
    phone_number: str,
    email: str,
    password: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_super_admin),
):

    full_name = full_name.strip()
    phone_number = phone_number.strip()
    email = email.strip().lower()

    if len(full_name) < 2:
        raise HTTPException(
            status_code=400,
            detail="Full name is too short.",
        )

    if len(password) < 8:
        raise HTTPException(
            status_code=400,
            detail="Password must contain at least 8 characters.",
        )

    existing_phone = (
        db.query(User)
        .filter(
            User.phone_number == phone_number
        )
        .first()
    )

    if existing_phone:
        raise HTTPException(
            status_code=400,
            detail="Phone number is already registered.",
        )

    existing_email = (
        db.query(User)
        .filter(
            User.email == email
        )
        .first()
    )

    if existing_email:
        raise HTTPException(
            status_code=400,
            detail="Email is already registered.",
        )

    admin = User(
        full_name=full_name,
        phone_number=phone_number,
        email=email,
        password_hash=hash_password(password),
        role="admin",
        is_active=True,
    )

    db.add(admin)
    db.commit()
    db.refresh(admin)

    return {
        "message": "Admin account created successfully.",
        "admin": {
            "id": admin.id,
            "full_name": admin.full_name,
            "phone_number": admin.phone_number,
            "email": admin.email,
            "role": admin.role,
            "is_active": admin.is_active,
            "created_at": admin.created_at,
        },
    }


@router.get("/admins/{admin_id}")
def admin_details(
    admin_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_super_admin),
):

    admin = get_admin_or_404(
        db,
        admin_id,
    )

    return {
        "id": admin.id,
        "full_name": admin.full_name,
        "phone_number": admin.phone_number,
        "email": admin.email,
        "role": admin.role,
        "is_active": admin.is_active,
        "created_at": admin.created_at,
    }


@router.patch("/admins/{admin_id}/status")
def update_admin_status(
    admin_id: int,
    is_active: bool,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_super_admin),
):

    admin = get_admin_or_404(
        db,
        admin_id,
    )

    admin.is_active = is_active

    db.commit()
    db.refresh(admin)

    return {
        "message": "Admin status updated successfully.",
        "id": admin.id,
        "is_active": admin.is_active,
    }


# ============================================================
# USER MANAGEMENT
# ============================================================

@router.get("/users")
def super_admin_users(
    search: str | None = None,
    role: str | None = None,
    status_filter: str | None = None,
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
    current_user: User = Depends(require_super_admin),
):

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
                detail="Invalid role.",
            )

        query = query.filter(
            User.role == role
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

    users = (
        query
        .order_by(
            User.created_at.desc()
        )
        .offset(offset)
        .limit(limit)
        .all()
    )

    return [
        {
            "id": user.id,
            "full_name": user.full_name,
            "phone_number": user.phone_number,
            "email": user.email,
            "role": user.role,
            "is_active": user.is_active,
            "created_at": user.created_at,
        }
        for user in users
    ]


@router.get("/users/{user_id}")
def super_admin_user_details(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_super_admin),
):

    user = get_user_or_404(
        db,
        user_id,
    )

    return {
        "id": user.id,
        "full_name": user.full_name,
        "phone_number": user.phone_number,
        "email": user.email,
        "role": user.role,
        "is_active": user.is_active,
        "created_at": user.created_at,
    }


# ============================================================
# USER ROLE MANAGEMENT
# ============================================================

@router.patch("/users/{user_id}/role")
def change_user_role(
    user_id: int,
    role: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_super_admin),
):

    if role not in ALLOWED_ROLES:
        raise HTTPException(
            status_code=400,
            detail=(
                "Invalid role. "
                "Allowed roles: passenger, driver, admin."
            ),
        )

    user = get_user_or_404(
        db,
        user_id,
    )

    if user.role == "super_admin":
        raise HTTPException(
            status_code=403,
            detail="Super Admin accounts cannot be modified here.",
        )

    if user.id == current_user.id:
        raise HTTPException(
            status_code=400,
            detail="You cannot change your own role.",
        )

    user.role = role

    db.commit()
    db.refresh(user)

    return {
        "message": "User role updated successfully.",
        "user_id": user.id,
        "role": user.role,
    }


# ============================================================
# USER STATUS MANAGEMENT
# ============================================================

@router.patch("/users/{user_id}/status")
def change_user_status(
    user_id: int,
    is_active: bool,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_super_admin),
):

    user = get_user_or_404(
        db,
        user_id,
    )

    if user.role == "super_admin":
        raise HTTPException(
            status_code=403,
            detail="Super Admin accounts cannot be modified here.",
        )

    if user.id == current_user.id:
        raise HTTPException(
            status_code=400,
            detail="You cannot change your own account status.",
        )

    user.is_active = is_active

    if (
        user.role == "driver"
        and not is_active
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

    db.commit()
    db.refresh(user)

    return {
        "message": "User status updated successfully.",
        "user_id": user.id,
        "is_active": user.is_active,
    }


# ============================================================
# AUDIT LOGS
# ============================================================

@router.get("/audit-logs")
def super_admin_audit_logs(
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
    current_user: User = Depends(require_super_admin),
):

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

    return {
        "total": total,
        "limit": limit,
        "offset": offset,
        "logs": logs,
    }


@router.get("/audit-logs/{audit_log_id}")
def super_admin_audit_log(
    audit_log_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_super_admin),
):

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
# SYSTEM STATISTICS
# ============================================================

@router.get("/system/stats")
def system_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_super_admin),
):

    notifications = (
        db.query(Notification)
        .count()
    )

    unread_notifications = (
        db.query(Notification)
        .filter(
            Notification.is_read.is_(False)
        )
        .count()
    )

    wallet_transactions = (
        db.query(WalletTransaction)
        .count()
    )

    audit_logs = (
        db.query(AuditLog)
        .count()
    )

    driver_locations = (
        db.query(DriverLocation)
        .count()
    )

    return {
        "users": db.query(User).count(),
        "drivers": db.query(Driver).count(),
        "rides": db.query(Ride).count(),
        "notifications": notifications,
        "unread_notifications": unread_notifications,
        "wallet_transactions": wallet_transactions,
        "audit_logs": audit_logs,
        "driver_locations": driver_locations,
        "generated_at": now_utc(),
    }


# ============================================================
# SYSTEM HEALTH
# ============================================================

@router.get("/system/health")
def system_health(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_super_admin),
):

    try:
        db.execute(
            __import__("sqlalchemy").text(
                "SELECT 1"
            )
        )

        database_status = "healthy"

    except Exception:
        database_status = "unhealthy"

    return {
        "status": (
            "healthy"
            if database_status == "healthy"
            else "degraded"
        ),
        "database": database_status,
        "api": "healthy",
        "generated_at": now_utc(),
    }