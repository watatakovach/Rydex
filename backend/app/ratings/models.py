from datetime import datetime, timezone

from sqlalchemy import (
    Column,
    DateTime,
    ForeignKey,
    Integer,
    String,
    UniqueConstraint,
)

from app.database.database import Base


class DriverRating(Base):
    __tablename__ = "driver_ratings"

    __table_args__ = (
        UniqueConstraint(
            "ride_id",
            name="uq_driver_ratings_ride_id",
        ),
    )

    id = Column(Integer, primary_key=True, index=True)

    ride_id = Column(
        Integer,
        ForeignKey("rides.id"),
        nullable=False,
        index=True,
    )

    passenger_id = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=False,
        index=True,
    )

    driver_id = Column(
        Integer,
        ForeignKey("drivers.id"),
        nullable=False,
        index=True,
    )

    rating = Column(
        Integer,
        nullable=False,
        index=True,
    )

    comment = Column(
        String(500),
        nullable=True,
    )

    created_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
        index=True,
    )
