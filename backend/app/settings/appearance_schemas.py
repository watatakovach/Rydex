from datetime import datetime

from pydantic import BaseModel, ConfigDict



class AppearanceSettingsBase(BaseModel):

    app_name: str = "RYDEX"

    slogan: str = "Your Ride, Your Way"


    logo_url: str | None = None

    favicon_url: str | None = None


    theme_mode: str = "System Default"


    primary_color: str = "#000000"

    secondary_color: str = "#FFFFFF"


    dark_mode_enabled: bool = False


    compact_sidebar: bool = False

    animations_enabled: bool = True

    show_branding: bool = True


    dashboard_language: str = "English"

    rtl_support: bool = False


    splash_screen_logo: str | None = None

    show_company_name: bool = True



class AppearanceSettingsCreate(
    AppearanceSettingsBase
):
    pass



class AppearanceSettingsUpdate(BaseModel):

    app_name: str | None = None

    slogan: str | None = None

    logo_url: str | None = None

    favicon_url: str | None = None

    theme_mode: str | None = None

    primary_color: str | None = None

    secondary_color: str | None = None

    dark_mode_enabled: bool | None = None

    compact_sidebar: bool | None = None

    animations_enabled: bool | None = None

    show_branding: bool | None = None

    dashboard_language: str | None = None

    rtl_support: bool | None = None

    splash_screen_logo: str | None = None

    show_company_name: bool | None = None



class AppearanceSettingsResponse(
    AppearanceSettingsBase
):

    id: int

    created_at: datetime

    updated_at: datetime


    model_config = ConfigDict(
        from_attributes=True
    )