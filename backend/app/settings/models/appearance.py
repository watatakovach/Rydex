from sqlalchemy import (
    Column,
    Integer,
    String,
    Boolean,
    DateTime,
    func,
)

from app.database.database import Base



class AppearanceSettings(Base):

    __tablename__ = "appearance_settings"


    id = Column(
        Integer,
        primary_key=True,
        index=True
    )


    # Branding

    app_name = Column(
        String(150),
        default="RYDEX"
    )


    slogan = Column(
        String(255),
        default="Your Ride, Your Way"
    )


    logo_url = Column(
        String(255),
        nullable=True
    )


    favicon_url = Column(
        String(255),
        nullable=True
    )


    # Theme

    theme_mode = Column(
        String(50),
        default="System Default"
    )


    primary_color = Column(
        String(50),
        default="#000000"
    )


    secondary_color = Column(
        String(50),
        default="#FFFFFF"
    )


    dark_mode_enabled = Column(
        Boolean,
        default=False
    )


    # Interface

    compact_sidebar = Column(
        Boolean,
        default=False
    )


    animations_enabled = Column(
        Boolean,
        default=True
    )


    show_branding = Column(
        Boolean,
        default=True
    )


    # Language

    dashboard_language = Column(
        String(50),
        default="English"
    )


    rtl_support = Column(
        Boolean,
        default=False
    )


    # Mobile App Display

    splash_screen_logo = Column(
        String(255),
        nullable=True
    )


    show_company_name = Column(
        Boolean,
        default=True
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