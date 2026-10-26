from datetime import datetime, timezone

from sqlalchemy import Column, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from app.database.connection import Base


class Vehicle(Base):
    __tablename__ = "vehicles"

    id = Column(Integer, primary_key=True, index=True)

    driver_id = Column(
        Integer,
        ForeignKey("drivers.id"),
        nullable=False,
    )

    make = Column(
        String(50),
        nullable=False,
    )

    model = Column(
        String(50),
        nullable=False,
    )

    year = Column(
        Integer,
        nullable=False,
    )

    color = Column(
        String(30),
        nullable=False,
    )

    license_plate = Column(
        String(20),
        unique=True,
        nullable=False,
    )

    images = relationship(
        "VehicleImage",
        back_populates="vehicle",
        cascade="all, delete-orphan",
        order_by="VehicleImage.id",
    )


class VehicleImage(Base):
    __tablename__ = "vehicle_images"

    id = Column(Integer, primary_key=True, index=True)

    vehicle_id = Column(
        Integer,
        ForeignKey("vehicles.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    # Relative to UPLOAD_DIR, e.g. "vehicles/3/ab12cd.jpg"
    file_path = Column(
        String(255),
        nullable=False,
    )

    created_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    vehicle = relationship("Vehicle", back_populates="images")

    @property
    def url(self) -> str:
        return f"/uploads/{self.file_path}"
