from datetime import datetime

from pydantic import BaseModel, ConfigDict



class DeveloperSettingsBase(BaseModel):

    environment: str = "Production"


    api_base_url: str = "https://api.rydex.com"


    debug_mode: bool = False


    maintenance_mode: bool = False


    enable_system_logs: bool = True


    log_level: str = "INFO"


    api_rate_limit_enabled: bool = True


    requests_per_minute: int = 100


    webhooks_enabled: bool = True


    webhook_url: str | None = None


    firebase_project_id: str | None = None


    feature_flags_enabled: bool = True


    experimental_features_enabled: bool = False


    crash_reporting_enabled: bool = True


    error_reporting_service: str = "Sentry"



class DeveloperSettingsCreate(
    DeveloperSettingsBase
):
    pass



class DeveloperSettingsUpdate(BaseModel):

    environment: str | None = None

    api_base_url: str | None = None

    debug_mode: bool | None = None

    maintenance_mode: bool | None = None

    enable_system_logs: bool | None = None

    log_level: str | None = None

    api_rate_limit_enabled: bool | None = None

    requests_per_minute: int | None = None

    webhooks_enabled: bool | None = None

    webhook_url: str | None = None

    firebase_project_id: str | None = None

    feature_flags_enabled: bool | None = None

    experimental_features_enabled: bool | None = None

    crash_reporting_enabled: bool | None = None

    error_reporting_service: str | None = None



class DeveloperSettingsResponse(
    DeveloperSettingsBase
):

    id: int

    created_at: datetime

    updated_at: datetime


    model_config = ConfigDict(
        from_attributes=True
    )