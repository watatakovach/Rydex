from sqlalchemy import (
    Column,
    Integer,
    String,
    Boolean,
    DateTime,
    func,
)

from app.database.database import Base



class BackupSettings(Base):

    __tablename__ = "backup_settings"


    id = Column(
        Integer,
        primary_key=True,
        index=True
    )


    # Backup Control

    automatic_backup_enabled = Column(
        Boolean,
        default=True
    )


    backup_frequency_hours = Column(
        Integer,
        default=24
    )


    backup_retention_days = Column(
        Integer,
        default=30
    )


    # Storage

    storage_provider = Column(
        String(100),
        default="Local Storage"
    )


    cloud_backup_enabled = Column(
        Boolean,
        default=False
    )


    cloud_bucket_name = Column(
        String(255),
        nullable=True
    )


    # Data Selection

    backup_database = Column(
        Boolean,
        default=True
    )


    backup_user_data = Column(
        Boolean,
        default=True
    )


    backup_driver_data = Column(
        Boolean,
        default=True
    )


    backup_ride_data = Column(
        Boolean,
        default=True
    )


    backup_payment_data = Column(
        Boolean,
        default=True
    )


    backup_logs = Column(
        Boolean,
        default=True
    )


    # Security

    encrypt_backups = Column(
        Boolean,
        default=True
    )


    encryption_method = Column(
        String(50),
        default="AES-256"
    )


    # Restore

    allow_restore = Column(
        Boolean,
        default=True
    )


    maximum_restore_points = Column(
        Integer,
        default=10
    )


    # Notifications

    backup_success_notification = Column(
        Boolean,
        default=True
    )


    backup_failure_notification = Column(
        Boolean,
        default=True
    )


    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now()
    )


    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now()
    )