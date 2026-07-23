from datetime import datetime, timezone

from sqlalchemy import Column, DateTime, Float, ForeignKey, Integer, String

from app.database.connection import Base


class Ride(Base):
    __tablename__ = "rides"

    id = Column(Integer, primary_key=True, index=True)

    passenger_id = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=False,
    )

    driver_id = Column(
        Integer,
        ForeignKey("drivers.id"),
        nullable=True,
    )

    pickup_latitude = Column(
        Float,
        nullable=False,
    )

    pickup_longitude = Column(
        Float,
        nullable=False,
    )

    destination_latitude = Column(
        Float,
        nullable=False,
    )

    destination_longitude = Column(
        Float,
        nullable=False,
    )

    status = Column(
        String(30),
        default="requested",
        nullable=False,
    )

    estimated_fare = Column(
        Float,
        nullable=True,
    )

    final_fare = Column(
        Float,
        nullable=True,
    )

    requested_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    completed_at = Column(
        DateTime(timezone=True),
        nullable=True,
    )