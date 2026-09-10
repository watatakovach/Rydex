from sqlalchemy import (
    Column,
    Integer,
    String,
    Boolean,
    DateTime,
    func,
)

from app.database.database import Base



class AnalyticsSettings(Base):

    __tablename__ = "analytics_settings"


    id = Column(
        Integer,
        primary_key=True,
        index=True
    )


    # Main Analytics

    analytics_enabled = Column(
        Boolean,
        default=True
    )


    track_user_behaviour = Column(
        Boolean,
        default=False
    )


    collect_ride_analytics = Column(
        Boolean,
        default=True
    )


    collect_driver_analytics = Column(
        Boolean,
        default=True
    )


    collect_passenger_analytics = Column(
        Boolean,
        default=True
    )


    collect_revenue_analytics = Column(
        Boolean,
        default=True
    )


    # Reports

    automatic_reports_enabled = Column(
        Boolean,
        default=True
    )


    report_frequency = Column(
        String(50),
        default="Daily"
    )


    report_format = Column(
        String(20),
        default="PDF"
    )


    report_email = Column(
        String(150),
        nullable=True
    )


    # Data Storage

    data_retention_days = Column(
        Integer,
        default=365
    )


    enable_data_export = Column(
        Boolean,
        default=True
    )


    export_format = Column(
        String(20),
        default="CSV"
    )


    # Dashboard

    show_revenue_dashboard = Column(
        Boolean,
        default=True
    )


    show_driver_statistics = Column(
        Boolean,
        default=True
    )


    show_passenger_statistics = Column(
        Boolean,
        default=True
    )


    show_ride_statistics = Column(
        Boolean,
        default=True
    )


    # Performance Metrics

    track_driver_acceptance_rate = Column(
        Boolean,
        default=True
    )


    track_driver_completion_rate = Column(
        Boolean,
        default=True
    )


    track_cancelled_rides = Column(
        Boolean,
        default=True
    )


    track_average_wait_time = Column(
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