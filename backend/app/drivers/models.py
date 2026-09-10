from datetime import datetime, timezone

from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    ForeignKey,
    Integer,
    String,
    Float,
)

from sqlalchemy.orm import relationship

from app.database.database import Base


class Driver(Base):
    __tablename__ = "drivers"

    # ========================================================
    # PRIMARY KEY
    # ========================================================

    id = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    # ========================================================
    # USER RELATIONSHIP
    # ========================================================

    user_id = Column(
        Integer,
        ForeignKey("users.id"),
        unique=True,
        nullable=False,
        index=True,
    )

    # ========================================================
    # DRIVER LICENSE
    # ========================================================

    license_number = Column(
        String(50),
        unique=True,
        nullable=False,
    )

    # ========================================================
    # VEHICLE INFORMATION
    # ========================================================

    vehicle_make = Column(
        String(100),
        nullable=True,
    )

    vehicle_model = Column(
        String(100),
        nullable=True,
    )

    vehicle_color = Column(
        String(50),
        nullable=True,
    )

    vehicle_plate = Column(
        String(30),
        unique=True,
        nullable=True,
    )

    # ========================================================
    # DRIVER PHOTOS
    # ========================================================

    profile_photo = Column(
        String,
        nullable=True,
    )

    vehicle_photo = Column(
        String,
        nullable=True,
    )

        # ========================================================
    # VERIFICATION DOCUMENTS
    # ========================================================

    driving_license_document = Column(
        String,
        nullable=True,
    )

    national_id_document = Column(
        String,
        nullable=True,
    )

    vehicle_document = Column(
        String,
        nullable=True,
    )

    # ========================================================
    # DRIVER STATUS
    # ========================================================

    is_verified = Column(
        Boolean,
        default=False,
        nullable=False,
    )

    is_online = Column(
        Boolean,
        default=False,
        nullable=False,
    )

    # ========================================================
    # LIVE LOCATION
    # ========================================================

    latitude = Column(
        Float,
        nullable=True,
    )

    longitude = Column(
        Float,
        nullable=True,
    )

    location_updated_at = Column(
        DateTime(timezone=True),
        nullable=True,
        index=True
    )

    # ========================================================
    # CREATED DATE
    # ========================================================

    created_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    # ========================================================
    # USER RELATIONSHIP
    # ========================================================

    user = relationship(
        "User",
        back_populates="driver",
    )