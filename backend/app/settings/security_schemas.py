from datetime import datetime

from pydantic import BaseModel, ConfigDict


class SecuritySettingsBase(BaseModel):
    # Authentication
    jwt_expiry_minutes: int = 60
    refresh_token_expiry_days: int = 30
    allow_multiple_sessions: bool = True
    force_logout_on_password_change: bool = True

    # Password Policy
    minimum_password_length: int = 8
    require_uppercase: bool = True
    require_lowercase: bool = True
    require_numbers: bool = True
    require_special_characters: bool = False

    # Login Protection
    max_login_attempts: int = 5
    account_lock_duration_minutes: int = 30
    enable_login_notifications: bool = True

    # Two Factor Authentication
    two_factor_enabled: bool = False
    admin_two_factor_required: bool = True
    driver_two_factor_enabled: bool = False

    # API Security
    api_rate_limit_enabled: bool = True
    api_requests_per_minute: int = 100
    allow_public_api_access: bool = False

    # Audit
    audit_logs_enabled: bool = True
    store_login_history: bool = True
    login_history_days: int = 90

    # Encryption
    encryption_enabled: bool = True
    data_encryption_algorithm: str = "AES-256"


class SecuritySettingsCreate(SecuritySettingsBase):
    pass


class SecuritySettingsUpdate(BaseModel):
    jwt_expiry_minutes: int | None = None
    refresh_token_expiry_days: int | None = None
    allow_multiple_sessions: bool | None = None
    force_logout_on_password_change: bool | None = None

    minimum_password_length: int | None = None
    require_uppercase: bool | None = None
    require_lowercase: bool | None = None
    require_numbers: bool | None = None
    require_special_characters: bool | None = None

    max_login_attempts: int | None = None
    account_lock_duration_minutes: int | None = None
    enable_login_notifications: bool | None = None

    two_factor_enabled: bool | None = None
    admin_two_factor_required: bool | None = None
    driver_two_factor_enabled: bool | None = None

    api_rate_limit_enabled: bool | None = None
    api_requests_per_minute: int | None = None
    allow_public_api_access: bool | None = None

    audit_logs_enabled: bool | None = None
    store_login_history: bool | None = None
    login_history_days: int | None = None

    encryption_enabled: bool | None = None
    data_encryption_algorithm: str | None = None


class SecuritySettingsResponse(SecuritySettingsBase):
    id: int
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(
        from_attributes=True
    )