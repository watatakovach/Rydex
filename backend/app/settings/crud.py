from sqlalchemy.orm import Session


from .models import (
    GeneralSettings,
    PaymentSettings,
    RideSettings,
    DriverSettings,
    PassengerSettings,
    NotificationSettings,
    MapSettings,
    SecuritySettings,
    AnalyticsSettings,
    BackupSettings,
    AppearanceSettings,
    DeveloperSettings,
)



# ==================================================
# GENERIC HELPERS
# ==================================================


def update_object(
    obj,
    data
):

    update_data = data.model_dump(
        exclude_unset=True
    )


    for key, value in update_data.items():

        setattr(
            obj,
            key,
            value
        )


    return obj




def save(
    db,
    obj
):

    db.commit()

    db.refresh(obj)

    return obj




def get_or_create(
    db,
    model
):

    settings = (
        db.query(model)
        .first()
    )


    if not settings:

        settings = model()

        db.add(settings)

        db.commit()

        db.refresh(settings)


    return settings




# ==================================================
# GENERAL SETTINGS
# ==================================================


def get_general_settings(db):

    return get_or_create(
        db,
        GeneralSettings
    )



def update_general_settings(
    db,
    data
):

    settings = get_general_settings(db)

    update_object(
        settings,
        data
    )

    return save(
        db,
        settings
    )




# ==================================================
# PAYMENT SETTINGS
# ==================================================


def get_payment_settings(db):

    return get_or_create(
        db,
        PaymentSettings
    )



def update_payment_settings(
    db,
    data
):

    settings = get_payment_settings(db)

    update_object(
        settings,
        data
    )

    return save(
        db,
        settings
    )




# ==================================================
# RIDE SETTINGS
# ==================================================


def get_ride_settings(db):

    return get_or_create(
        db,
        RideSettings
    )



def update_ride_settings(
    db,
    data
):
    settings = get_ride_settings(db)

    update_data = data.model_dump(
        exclude_unset=True
    )

    non_negative_fields = {
        "search_radius_km",
        "maximum_search_radius_km",
        "max_driver_results",
        "ride_request_timeout_seconds",
        "driver_accept_timeout_seconds",
        "driver_arrival_timeout_minutes",
        "maximum_reassignments",
        "maximum_schedule_days",
        "cancellation_fee_amount",
        "minimum_fare",
        "base_fare",
        "price_per_km",
        "price_per_minute",
    }

    for field in non_negative_fields:
        value = update_data.get(field)

        if value is not None and value < 0:
            raise ValueError(
                f"{field} cannot be negative."
            )

    search_radius = update_data.get(
        "search_radius_km"
    )

    if (
        search_radius is not None
        and search_radius <= 0
    ):
        raise ValueError(
            "search_radius_km must be greater than 0."
        )

    maximum_radius = update_data.get(
        "maximum_search_radius_km"
    )

    if (
        maximum_radius is not None
        and maximum_radius <= 0
    ):
        raise ValueError(
            "maximum_search_radius_km must be greater than 0."
        )

    if (
        search_radius is not None
        and maximum_radius is not None
        and search_radius > maximum_radius
    ):
        raise ValueError(
            "search_radius_km cannot exceed "
            "maximum_search_radius_km."
        )

    max_results = update_data.get(
        "max_driver_results"
    )

    if (
        max_results is not None
        and max_results < 1
    ):
        raise ValueError(
            "max_driver_results must be at least 1."
        )

    request_timeout = update_data.get(
        "ride_request_timeout_seconds"
    )

    if (
        request_timeout is not None
        and request_timeout < 1
    ):
        raise ValueError(
            "ride_request_timeout_seconds "
            "must be at least 1 second."
        )

    accept_timeout = update_data.get(
        "driver_accept_timeout_seconds"
    )

    if (
        accept_timeout is not None
        and accept_timeout < 1
    ):
        raise ValueError(
            "driver_accept_timeout_seconds "
            "must be at least 1 second."
        )

    maximum_reassignments = update_data.get(
        "maximum_reassignments"
    )

    if (
        maximum_reassignments is not None
        and maximum_reassignments < 0
    ):
        raise ValueError(
            "maximum_reassignments cannot be negative."
        )

    minimum_fare = update_data.get(
        "minimum_fare"
    )

    base_fare = update_data.get(
        "base_fare"
    )

    if (
        minimum_fare is not None
        and base_fare is not None
        and minimum_fare < base_fare
    ):
        raise ValueError(
            "minimum_fare cannot be lower than base_fare."
        )

    update_object(
        settings,
        data
    )

    return save(
        db,
        settings
    )




# ==================================================
# DRIVER SETTINGS
# ==================================================


def get_driver_settings(db):

    return get_or_create(
        db,
        DriverSettings
    )



def update_driver_settings(
    db,
    data
):

    settings = get_driver_settings(db)

    update_object(
        settings,
        data
    )

    return save(
        db,
        settings
    )




# ==================================================
# PASSENGER SETTINGS
# ==================================================


def get_passenger_settings(db):

    return get_or_create(
        db,
        PassengerSettings
    )



def update_passenger_settings(
    db,
    data
):

    settings = get_passenger_settings(db)

    update_object(
        settings,
        data
    )

    return save(
        db,
        settings
    )




# ==================================================
# NOTIFICATION SETTINGS
# ==================================================


def get_notification_settings(db):

    return get_or_create(
        db,
        NotificationSettings
    )



def update_notification_settings(
    db,
    data
):

    settings = get_notification_settings(db)

    update_object(
        settings,
        data
    )

    return save(
        db,
        settings
    )




# ==================================================
# MAP SETTINGS
# ==================================================


def get_map_settings(db):

    return get_or_create(
        db,
        MapSettings
    )



def update_map_settings(
    db,
    data
):

    settings = get_map_settings(db)

    update_object(
        settings,
        data
    )

    return save(
        db,
        settings
    )




# ==================================================
# SECURITY SETTINGS
# ==================================================


def get_security_settings(db):

    return get_or_create(
        db,
        SecuritySettings
    )



def update_security_settings(
    db,
    data
):

    settings = get_security_settings(db)

    update_object(
        settings,
        data
    )

    return save(
        db,
        settings
    )




# ==================================================
# ANALYTICS SETTINGS
# ==================================================


def get_analytics_settings(db):

    return get_or_create(
        db,
        AnalyticsSettings
    )



def update_analytics_settings(
    db,
    data
):

    settings = get_analytics_settings(db)

    update_object(
        settings,
        data
    )

    return save(
        db,
        settings
    )




# ==================================================
# BACKUP SETTINGS
# ==================================================


def get_backup_settings(db):

    return get_or_create(
        db,
        BackupSettings
    )



def update_backup_settings(
    db,
    data
):

    settings = get_backup_settings(db)

    update_object(
        settings,
        data
    )

    return save(
        db,
        settings
    )




# ==================================================
# APPEARANCE SETTINGS
# ==================================================


def get_appearance_settings(db):

    return get_or_create(
        db,
        AppearanceSettings
    )



def update_appearance_settings(
    db,
    data
):

    settings = get_appearance_settings(db)

    update_object(
        settings,
        data
    )

    return save(
        db,
        settings
    )




# ==================================================
# DEVELOPER SETTINGS
# ==================================================


def get_developer_settings(db):

    return get_or_create(
        db,
        DeveloperSettings
    )



def update_developer_settings(
    db,
    data
):

    settings = get_developer_settings(db)

    update_object(
        settings,
        data
    )

    return save(
        db,
        settings
    )