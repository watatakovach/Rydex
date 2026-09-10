from datetime import datetime

from pydantic import BaseModel, ConfigDict


class AnalyticsSettingsBase(BaseModel):
    # Main Analytics
    analytics_enabled: bool = True
    track_user_behaviour: bool = False

    collect_ride_analytics: bool = True
    collect_driver_analytics: bool = True
    collect_passenger_analytics: bool = True
    collect_revenue_analytics: bool = True

    # Reports
    automatic_reports_enabled: bool = True
    report_frequency: str = "Daily"
    report_format: str = "PDF"
    report_email: str | None = None

    # Data Storage
    data_retention_days: int = 365
    enable_data_export: bool = True
    export_format: str = "CSV"

    # Dashboard
    show_revenue_dashboard: bool = True
    show_driver_statistics: bool = True
    show_passenger_statistics: bool = True
    show_ride_statistics: bool = True

    # Performance Metrics
    track_driver_acceptance_rate: bool = True
    track_driver_completion_rate: bool = True
    track_cancelled_rides: bool = True
    track_average_wait_time: bool = True


class AnalyticsSettingsCreate(AnalyticsSettingsBase):
    pass


class AnalyticsSettingsUpdate(BaseModel):
    analytics_enabled: bool | None = None
    track_user_behaviour: bool | None = None

    collect_ride_analytics: bool | None = None
    collect_driver_analytics: bool | None = None
    collect_passenger_analytics: bool | None = None
    collect_revenue_analytics: bool | None = None

    automatic_reports_enabled: bool | None = None
    report_frequency: str | None = None
    report_format: str | None = None
    report_email: str | None = None

    data_retention_days: int | None = None
    enable_data_export: bool | None = None
    export_format: str | None = None

    show_revenue_dashboard: bool | None = None
    show_driver_statistics: bool | None = None
    show_passenger_statistics: bool | None = None
    show_ride_statistics: bool | None = None

    track_driver_acceptance_rate: bool | None = None
    track_driver_completion_rate: bool | None = None
    track_cancelled_rides: bool | None = None
    track_average_wait_time: bool | None = None


class AnalyticsSettingsResponse(AnalyticsSettingsBase):
    id: int
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(
        from_attributes=True
    )