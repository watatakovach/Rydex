from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.database.connection import get_db
from app.drivers.models import Driver
from app.users.models import User
from app.admin.schemas import (
    DriverVerification,
    PendingDriverResponse,
)


router = APIRouter(
    prefix="/admin",
    tags=["Admin"],
)


@router.get(
    "/drivers/pending",
    response_model=list[PendingDriverResponse],
)
def get_pending_drivers(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # Temporary admin check
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required",
        )

    drivers = (
        db.query(Driver)
        .filter(Driver.is_verified == False)
        .all()
    )

    return drivers


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
    # Temporary admin check
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required",
        )

    driver = (
        db.query(Driver)
        .filter(Driver.id == driver_id)
        .first()
    )

    if not driver:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Driver not found",
        )

    driver.is_verified = verification.is_verified

    # If rejected, make sure driver cannot be online
    if not verification.is_verified:
        driver.is_online = False

    db.commit()
    db.refresh(driver)

    return driver