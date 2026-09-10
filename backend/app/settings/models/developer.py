from sqlalchemy import (
    Column,
    Integer,
    String,
    Boolean,
    DateTime,
    func,
)

from app.database.database import Base



class DeveloperSettings(Base):

    __tablename__ = "developer_settings"


    id = Column(
        Integer,
        primary_key=True,
        index=True
    )


    # Environment

    environment = Column(
        String(50),
        default="Production"
    )


    api_base_url = Column(
        String(255),
        default="https://api.rydex.com"
    )


    # Debugging

    debug_mode = Column(
        Boolean,
        default=False
    )


    maintenance_mode = Column(
        Boolean,
        default=False
    )


    enable_system_logs = Column(
        Boolean,
        default=True
    )


    log_level = Column(
        String(50),
        default="INFO"
    )


    # API Security

    api_rate_limit_enabled = Column(
        Boolean,
        default=True
    )


    requests_per_minute = Column(
        Integer,
        default=100
    )


    # Webhooks

    webhooks_enabled = Column(
        Boolean,
        default=True
    )


    webhook_url = Column(
        String(255),
        nullable=True
    )


    # Firebase / Notifications

    firebase_project_id = Column(
        String(255),
        nullable=True
    )


    # Feature Flags

    feature_flags_enabled = Column(
        Boolean,
        default=True
    )


    experimental_features_enabled = Column(
        Boolean,
        default=False
    )


    # Error Monitoring

    crash_reporting_enabled = Column(
        Boolean,
        default=True
    )


    error_reporting_service = Column(
        String(100),
        default="Sentry"
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