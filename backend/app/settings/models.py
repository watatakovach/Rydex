from sqlalchemy import (
    Column,
    Integer,
    String,
    Boolean,
    DateTime,
    func,
)

from app.database.database import Base



class GeneralSettings(Base):

    __tablename__ = "general_settings"


    id = Column(
        Integer,
        primary_key=True,
        index=True
    )


    company_name = Column(
        String(150),
        nullable=False,
        default="RYDEX"
    )


    company_email = Column(
        String(150),
        nullable=True
    )


    company_phone = Column(
        String(50),
        nullable=True
    )


    company_address = Column(
        String(255),
        nullable=True
    )


    website = Column(
        String(255),
        nullable=True
    )


    logo = Column(
        String(255),
        nullable=True
    )


    timezone = Column(
        String(100),
        nullable=False,
        default="Africa/Nairobi"
    )


    language = Column(
        String(50),
        nullable=False,
        default="English"
    )


    currency = Column(
        String(10),
        nullable=False,
        default="KES"
    )


    currency_symbol = Column(
        String(10),
        nullable=False,
        default="KSh"
    )


    distance_unit = Column(
        String(20),
        nullable=False,
        default="Kilometers"
    )


    date_format = Column(
        String(30),
        nullable=False,
        default="dd/MM/yyyy"
    )


    time_format = Column(
        String(10),
        nullable=False,
        default="24 Hour"
    )


    maintenance_mode = Column(
        Boolean,
        default=False
    )


    registration_enabled = Column(
        Boolean,
        default=True
    )


    driver_registration_enabled = Column(
        Boolean,
        default=True
    )


    passenger_registration_enabled = Column(
        Boolean,
        default=True
    )


    # Added for production

    support_email = Column(
        String(150),
        nullable=True
    )


    support_phone = Column(
        String(50),
        nullable=True
    )


    app_version = Column(
        String(50),
        default="1.0.0"
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