from datetime import datetime

from pydantic import BaseModel, ConfigDict


class GeneralSettingsBase(BaseModel):

    company_name: str = "RYDEX"

    company_email: str | None = None

    company_phone: str | None = None

    company_address: str | None = None

    website: str | None = None

    logo: str | None = None

    timezone: str = "Africa/Nairobi"

    language: str = "English"

    currency: str = "KES"

    currency_symbol: str = "KSh"

    distance_unit: str = "Kilometers"

    date_format: str = "dd/MM/yyyy"

    time_format: str = "24 Hour"

    maintenance_mode: bool = False

    registration_enabled: bool = True

    driver_registration_enabled: bool = True

    passenger_registration_enabled: bool = True
    support_email: str | None = None
    support_phone: str | None = None
    app_version: str = "1.0.0"



class GeneralSettingsCreate(
    GeneralSettingsBase
):
    pass



class GeneralSettingsUpdate(BaseModel):

    company_name: str | None = None

    company_email: str | None = None

    company_phone: str | None = None

    company_address: str | None = None

    website: str | None = None

    logo: str | None = None

    timezone: str | None = None

    language: str | None = None

    currency: str | None = None

    currency_symbol: str | None = None

    distance_unit: str | None = None

    date_format: str | None = None

    time_format: str | None = None

    maintenance_mode: bool | None = None

    registration_enabled: bool | None = None

    driver_registration_enabled: bool | None = None

    passenger_registration_enabled: bool | None = None
    
    support_email: str | None = None
    support_phone: str | None = None
    app_version: str | None = None



class GeneralSettingsResponse(
    GeneralSettingsBase
):

    id: int

    created_at: datetime

    updated_at: datetime


    model_config = ConfigDict(
        from_attributes=True
    )