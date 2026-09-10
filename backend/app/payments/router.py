from datetime import datetime, timezone

from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    status,
)
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.database.database import get_db

from app.users.models import User
from app.drivers.models import Driver
from app.rides.models import Ride

from app.payments.models import Payment
from app.payments.schemas import (
    PaymentResponse,
    PaymentCompleteRequest,
)


router = APIRouter(
    prefix="/payments",
    tags=["Payments"],
)


# ============================================================
# GET PAYMENT FOR RIDE
# ============================================================

@router.get(
    "/ride/{ride_id}",
    response_model=PaymentResponse,
)
def get_ride_payment(
    ride_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    payment = (
        db.query(Payment)
        .filter(
            Payment.ride_id == ride_id
        )
        .first()
    )

    if not payment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Payment not found",
        )

    if payment.passenger_id == current_user.id:
        return payment

    driver = (
        db.query(Driver)
        .filter(
            Driver.user_id == current_user.id
        )
        .first()
    )

    if (
        driver
        and payment.driver_id == driver.id
    ):
        return payment

    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail="You are not authorized to view this payment",
    )


# ============================================================
# PASSENGER PAYMENT HISTORY
# ============================================================

@router.get(
    "/my-payments",
    response_model=list[PaymentResponse],
)
def get_my_payments(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return (
        db.query(Payment)
        .filter(
            Payment.passenger_id == current_user.id
        )
        .order_by(
            Payment.created_at.desc()
        )
        .all()
    )


# ============================================================
# COMPLETE PAYMENT
# ============================================================

@router.patch(
    "/{payment_id}/complete",
    response_model=PaymentResponse,
)
def complete_payment(
    payment_id: int,
    payment_data: PaymentCompleteRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    payment = (
        db.query(Payment)
        .filter(
            Payment.id == payment_id
        )
        .first()
    )

    if not payment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Payment not found",
        )

    if payment.passenger_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only the passenger can complete this payment",
        )

    if payment.status == "completed":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Payment has already been completed",
        )

    payment.status = "completed"

    payment.transaction_reference = (
        payment_data.transaction_reference
    )

    payment.completed_at = (
        datetime.now(timezone.utc)
    )

    db.commit()
    db.refresh(payment)

    return payment


# ============================================================
# DRIVER PAYMENT HISTORY
# ============================================================

@router.get(
    "/driver/history",
    response_model=list[PaymentResponse],
)
def get_driver_payment_history(
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

    return (
        db.query(Payment)
        .filter(
            Payment.driver_id == driver.id
        )
        .order_by(
            Payment.created_at.desc()
        )
        .all()
    )