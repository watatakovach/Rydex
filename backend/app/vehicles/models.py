from sqlalchemy import Column, ForeignKey, Integer, String

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