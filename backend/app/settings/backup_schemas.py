from datetime import datetime

from pydantic import BaseModel, ConfigDict


class BackupSettingsBase(BaseModel):
    # Backup Control
    automatic_backup_enabled: bool = True
    backup_frequency_hours: int = 24
    backup_retention_days: int = 30

    # Storage
    storage_provider: str = "Local Storage"
    cloud_backup_enabled: bool = False
    cloud_bucket_name: str | None = None

    # Data Selection
    backup_database: bool = True
    backup_user_data: bool = True
    backup_driver_data: bool = True
    backup_ride_data: bool = True
    backup_payment_data: bool = True
    backup_logs: bool = True

    # Security
    encrypt_backups: bool = True
    encryption_method: str = "AES-256"

    # Restore
    allow_restore: bool = True
    maximum_restore_points: int = 10

    # Notifications
    backup_success_notification: bool = True
    backup_failure_notification: bool = True


class BackupSettingsCreate(BackupSettingsBase):
    pass


class BackupSettingsUpdate(BaseModel):
    automatic_backup_enabled: bool | None = None
    backup_frequency_hours: int | None = None
    backup_retention_days: int | None = None

    storage_provider: str | None = None
    cloud_backup_enabled: bool | None = None
    cloud_bucket_name: str | None = None

    backup_database: bool | None = None
    backup_user_data: bool | None = None
    backup_driver_data: bool | None = None
    backup_ride_data: bool | None = None
    backup_payment_data: bool | None = None
    backup_logs: bool | None = None

    encrypt_backups: bool | None = None
    encryption_method: str | None = None

    allow_restore: bool | None = None
    maximum_restore_points: int | None = None

    backup_success_notification: bool | None = None
    backup_failure_notification: bool | None = None


class BackupSettingsResponse(BackupSettingsBase):
    id: int
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(
        from_attributes=True
    )