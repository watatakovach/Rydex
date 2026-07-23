from datetime import datetime, timezone

from sqlalchemy import Column, DateTime, Float, ForeignKey, Integer

from app.database.connection import Base


class DriverLocation(Base):
    __tablename__ = "driver_locations"

    id = Column(Integer, primary_key=True, index=True)

    driver_id = Column(
        Integer,
        ForeignKey("drivers.id"),
        unique=True,
        nullable=False,
    )

    latitude = Column(
        Float,
        nullable=False,
    )

    longitude = Column(
        Float,
        nullable=False,
    )

    updated_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )