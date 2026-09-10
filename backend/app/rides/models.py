from datetime import datetime, timezone

from sqlalchemy import (
    Column,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    String,
)

from app.database.database import Base


class Ride(Base):
    __tablename__ = "rides"

    # ============================================================
    # PRIMARY KEY
    # ============================================================

    id = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    # ============================================================
    # USERS
    # ============================================================

    passenger_id = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=False,
        index=True,
    )

    driver_id = Column(
        Integer,
        ForeignKey("drivers.id"),
        nullable=True,
        index=True,
    )

    # ============================================================
    # PICKUP LOCATION
    # ============================================================

    pickup_latitude = Column(
        Float,
        nullable=False,
    )

    pickup_longitude = Column(
        Float,
        nullable=False,
    )

    # ============================================================
    # DESTINATION
    # ============================================================

    destination_latitude = Column(
        Float,
        nullable=False,
    )

    destination_longitude = Column(
        Float,
        nullable=False,
    )

    # ============================================================
    # RIDE STATUS
    # ============================================================

    status = Column(
        String(30),
        default="requested",
        nullable=False,
        index=True,
    )

    # ============================================================
    # FARES
    # ============================================================

    estimated_fare = Column(
        Float,
        nullable=True,
    )

    final_fare = Column(
        Float,
        nullable=True,
    )

    # ============================================================
    # RIDE METRICS
    # ============================================================

    distance_km = Column(
        Float,
        nullable=True,
    )

    duration_minutes = Column(
        Float,
        nullable=True,
    )

    # ============================================================
    # RIDE TIMELINE
    # ============================================================

    requested_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
        index=True,
    )

    accepted_at = Column(
        DateTime(timezone=True),
        nullable=True,
    )

    started_at = Column(
        DateTime(timezone=True),
        nullable=True,
    )

    completed_at = Column(
        DateTime(timezone=True),
        nullable=True,
    )

    cancelled_at = Column(
        DateTime(timezone=True),
        nullable=True,
    )

    # ============================================================
    # CANCELLATION
    # ============================================================

    cancellation_reason = Column(
        String,
        nullable=True,
    )

    cancelled_by = Column(
        String(30),
        nullable=True,
    )

    # ============================================================
    # ADMIN ACTIONS / AUDIT
    # ============================================================

    admin_note = Column(
        String,
        nullable=True,
    )

    admin_action = Column(
        String(50),
        nullable=True,
    )

    admin_id = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=True,
        index=True
    )

    admin_action_at = Column(
        DateTime(timezone=True),
        nullable=True,
    )