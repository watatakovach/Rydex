from datetime import datetime, timezone

from sqlalchemy import (
    Column,
    DateTime,
    Float,
    ForeignKey,
    Integer,
)

from app.database.database import Base


class DriverWallet(Base):
    __tablename__ = "driver_wallets"

    # ============================================================
    # PRIMARY KEY
    # ============================================================

    id = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    # ============================================================
    # DRIVER
    # ============================================================

    driver_id = Column(
        Integer,
        ForeignKey("drivers.id"),
        unique=True,
        nullable=False,
        index=True,
    )

    # ============================================================
    # BALANCES
    # ============================================================

    available_balance = Column(
        Float,
        default=0.0,
        nullable=False,
    )

    pending_balance = Column(
        Float,
        default=0.0,
        nullable=False,
    )

    total_earned = Column(
        Float,
        default=0.0,
        nullable=False,
    )

    total_withdrawn = Column(
        Float,
        default=0.0,
        nullable=False,
    )

    # ============================================================
    # TIMESTAMPS
    # ============================================================

    created_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    updated_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )