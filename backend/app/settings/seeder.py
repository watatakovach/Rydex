from sqlalchemy.orm import Session

from .models import (
    GeneralSettings,
    PaymentSettings,
    RideSettings,
    DriverSettings,
    PassengerSettings,
    NotificationSettings,
    MapSettings,
    SecuritySettings,
    AnalyticsSettings,
    BackupSettings,
    AppearanceSettings,
    DeveloperSettings,
)


def create_if_missing(
    db: Session,
    model,
):
    existing = (
        db.query(model)
        .first()
    )

    if not existing:
        db.add(
            model()
        )


def seed_settings(
    db: Session,
):
    settings_models = [
        GeneralSettings,
        PaymentSettings,
        RideSettings,
        DriverSettings,
        PassengerSettings,
        NotificationSettings,
        MapSettings,
        SecuritySettings,
        AnalyticsSettings,
        BackupSettings,
        AppearanceSettings,
        DeveloperSettings,
    ]

    for model in settings_models:
        create_if_missing(
            db,
            model,
        )

    db.commit()