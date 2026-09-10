from sqlalchemy import (
    Column,
    Integer,
    String,
    Boolean,
    DateTime,
    func,
)

from app.database.database import Base



class SecuritySettings(Base):

    __tablename__ = "security_settings"


    id = Column(
        Integer,
        primary_key=True,
        index=True
    )


    # Authentication

    jwt_expiry_minutes = Column(
        Integer,
        default=60
    )


    refresh_token_expiry_days = Column(
        Integer,
        default=30
    )


    allow_multiple_sessions = Column(
        Boolean,
        default=True
    )


    force_logout_on_password_change = Column(
        Boolean,
        default=True
    )


    # Password Policy

    minimum_password_length = Column(
        Integer,
        default=8
    )


    require_uppercase = Column(
        Boolean,
        default=True
    )


    require_lowercase = Column(
        Boolean,
        default=True
    )


    require_numbers = Column(
        Boolean,
        default=True
    )


    require_special_characters = Column(
        Boolean,
        default=False
    )


    # Login Protection

    max_login_attempts = Column(
        Integer,
        default=5
    )


    account_lock_duration_minutes = Column(
        Integer,
        default=30
    )


    enable_login_notifications = Column(
        Boolean,
        default=True
    )


    # Two Factor Authentication

    two_factor_enabled = Column(
        Boolean,
        default=False
    )


    admin_two_factor_required = Column(
        Boolean,
        default=True
    )


    driver_two_factor_enabled = Column(
        Boolean,
        default=False
    )


    # API Security

    api_rate_limit_enabled = Column(
        Boolean,
        default=True
    )


    api_requests_per_minute = Column(
        Integer,
        default=100
    )


    allow_public_api_access = Column(
        Boolean,
        default=False
    )


    # Audit

    audit_logs_enabled = Column(
        Boolean,
        default=True
    )


    store_login_history = Column(
        Boolean,
        default=True
    )


    login_history_days = Column(
        Integer,
        default=90
    )


    # Encryption

    encryption_enabled = Column(
        Boolean,
        default=True
    )


    data_encryption_algorithm = Column(
        String(50),
        default="AES-256"
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