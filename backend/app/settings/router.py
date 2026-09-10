
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth.dependencies import (
    require_admin,
    require_super_admin,
)
from app.database.database import get_db

from . import crud

from .schemas import (
    GeneralSettingsResponse,
    GeneralSettingsUpdate,
)

from .payment_schemas import (
    PaymentSettingsResponse,
    PaymentSettingsUpdate,
)

from .ride_schemas import (
    RideSettingsResponse,
    RideSettingsUpdate,
)

from .driver_schemas import (
    DriverSettingsResponse,
    DriverSettingsUpdate,
)

from .passenger_schemas import (
    PassengerSettingsResponse,
    PassengerSettingsUpdate,
)

from .notification_schemas import (
    NotificationSettingsResponse,
    NotificationSettingsUpdate,
)

from .map_schemas import (
    MapSettingsResponse,
    MapSettingsUpdate,
)

from .security_schemas import (
    SecuritySettingsResponse,
    SecuritySettingsUpdate,
)

from .analytics_schemas import (
    AnalyticsSettingsResponse,
    AnalyticsSettingsUpdate,
)

from .backup_schemas import (
    BackupSettingsResponse,
    BackupSettingsUpdate,
)

from .appearance_schemas import (
    AppearanceSettingsResponse,
    AppearanceSettingsUpdate,
)

from .developer_schemas import (
    DeveloperSettingsResponse,
    DeveloperSettingsUpdate,
)


router = APIRouter(
    prefix="/admin/settings",
    tags=["Admin Settings"],
)


# ============================================================
# GENERAL
# Admin + Super Admin
# ============================================================

@router.get(
    "/general",
    response_model=GeneralSettingsResponse,
)
def get_general(
    db: Session = Depends(get_db),
    current_user=Depends(require_admin),
):
    return crud.get_general_settings(db)


@router.patch(
    "/general",
    response_model=GeneralSettingsResponse,
)
def update_general(
    data: GeneralSettingsUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(require_admin),
):
    return crud.update_general_settings(db, data)


# ============================================================
# PAYMENT
# Admin + Super Admin
# ============================================================

@router.get(
    "/payment",
    response_model=PaymentSettingsResponse,
)
def get_payment(
    db: Session = Depends(get_db),
    current_user=Depends(require_admin),
):
    return crud.get_payment_settings(db)


@router.patch(
    "/payment",
    response_model=PaymentSettingsResponse,
)
def update_payment(
    data: PaymentSettingsUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(require_admin),
):
    return crud.update_payment_settings(db, data)


# ============================================================
# RIDE
# Admin + Super Admin
# ============================================================

@router.get(
    "/ride",
    response_model=RideSettingsResponse,
)
def get_ride(
    db: Session = Depends(get_db),
    current_user=Depends(require_admin),
):
    return crud.get_ride_settings(db)


@router.patch(
    "/ride",
    response_model=RideSettingsResponse,
)
def update_ride(
    data: RideSettingsUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(require_admin),
):
    return crud.update_ride_settings(db, data)


# ============================================================
# DRIVER
# Admin + Super Admin
# ============================================================

@router.get(
    "/driver",
    response_model=DriverSettingsResponse,
)
def get_driver(
    db: Session = Depends(get_db),
    current_user=Depends(require_admin),
):
    return crud.get_driver_settings(db)


@router.patch(
    "/driver",
    response_model=DriverSettingsResponse,
)
def update_driver(
    data: DriverSettingsUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(require_admin),
):
    return crud.update_driver_settings(db, data)


# ============================================================
# PASSENGER
# Admin + Super Admin
# ============================================================

@router.get(
    "/passenger",
    response_model=PassengerSettingsResponse,
)
def get_passenger(
    db: Session = Depends(get_db),
    current_user=Depends(require_admin),
):
    return crud.get_passenger_settings(db)


@router.patch(
    "/passenger",
    response_model=PassengerSettingsResponse,
)
def update_passenger(
    data: PassengerSettingsUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(require_admin),
):
    return crud.update_passenger_settings(db, data)


# ============================================================
# NOTIFICATIONS
# Admin + Super Admin
# ============================================================

@router.get(
    "/notifications",
    response_model=NotificationSettingsResponse,
)
def get_notifications(
    db: Session = Depends(get_db),
    current_user=Depends(require_admin),
):
    return crud.get_notification_settings(db)


@router.patch(
    "/notifications",
    response_model=NotificationSettingsResponse,
)
def update_notifications(
    data: NotificationSettingsUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(require_admin),
):
    return crud.update_notification_settings(db, data)


# ============================================================
# MAPS
# Admin + Super Admin
# ============================================================

@router.get(
    "/maps",
    response_model=MapSettingsResponse,
)
def get_maps(
    db: Session = Depends(get_db),
    current_user=Depends(require_admin),
):
    return crud.get_map_settings(db)


@router.patch(
    "/maps",
    response_model=MapSettingsResponse,
)
def update_maps(
    data: MapSettingsUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(require_admin),
):
    return crud.update_map_settings(db, data)


# ============================================================
# SECURITY
# SUPER ADMIN ONLY
# ============================================================

@router.get(
    "/security",
    response_model=SecuritySettingsResponse,
)
def get_security(
    db: Session = Depends(get_db),
    current_user=Depends(require_super_admin),
):
    return crud.get_security_settings(db)


@router.patch(
    "/security",
    response_model=SecuritySettingsResponse,
)
def update_security(
    data: SecuritySettingsUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(require_super_admin),
):
    return crud.update_security_settings(db, data)


# ============================================================
# ANALYTICS
# Admin + Super Admin
# ============================================================

@router.get(
    "/analytics",
    response_model=AnalyticsSettingsResponse,
)
def get_analytics(
    db: Session = Depends(get_db),
    current_user=Depends(require_admin),
):
    return crud.get_analytics_settings(db)


@router.patch(
    "/analytics",
    response_model=AnalyticsSettingsResponse,
)
def update_analytics(
    data: AnalyticsSettingsUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(require_admin),
):
    return crud.update_analytics_settings(db, data)


# ============================================================
# BACKUP
# SUPER ADMIN ONLY
# ============================================================

@router.get(
    "/backup",
    response_model=BackupSettingsResponse,
)
def get_backup(
    db: Session = Depends(get_db),
    current_user=Depends(require_super_admin),
):
    return crud.get_backup_settings(db)


@router.patch(
    "/backup",
    response_model=BackupSettingsResponse,
)
def update_backup(
    data: BackupSettingsUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(require_super_admin),
):
    return crud.update_backup_settings(db, data)


# ============================================================
# APPEARANCE
# Admin + Super Admin
# ============================================================

@router.get(
    "/appearance",
    response_model=AppearanceSettingsResponse,
)
def get_appearance(
    db: Session = Depends(get_db),
    current_user=Depends(require_admin),
):
    return crud.get_appearance_settings(db)


@router.patch(
    "/appearance",
    response_model=AppearanceSettingsResponse,
)
def update_appearance(
    data: AppearanceSettingsUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(require_admin),
):
    return crud.update_appearance_settings(db, data)


# ============================================================
# DEVELOPER
# SUPER ADMIN ONLY
# ============================================================

@router.get(
    "/developer",
    response_model=DeveloperSettingsResponse,
)
def get_developer(
    db: Session = Depends(get_db),
    current_user=Depends(require_super_admin),
):
    return crud.get_developer_settings(db)


@router.patch(
    "/developer",
    response_model=DeveloperSettingsResponse,
)
def update_developer(
    data: DeveloperSettingsUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(require_super_admin),
):
    return crud.update_developer_settings(db, data)

