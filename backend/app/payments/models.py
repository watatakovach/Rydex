from datetime import datetime, timezone

from sqlalchemy import (
    Column,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    String,
    UniqueConstraint,
)

from app.database.database import Base


class Payment(Base):
    __tablename__ = "payments"

    __table_args__ = (
        UniqueConstraint(
            "ride_id",
            name="uq_payment_ride_id",
        ),
    )

    id = Column(
        Integer,
        primary_key=True,
        index=True,
    )

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
        nullable=True,
        index=True,
    )

    amount = Column(
        Float,
        nullable=False,
    )

    payment_method = Column(
        String(30),
        nullable=False,
        default="cash",
    )

    status = Column(
        String(30),
        nullable=False,
        default="pending",
        index=True,
    )

    transaction_reference = Column(
        String(100),
        nullable=True,
        unique=True,
        index=True,
    )

    created_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    completed_at = Column(
        DateTime(timezone=True),
        nullable=True,
    )