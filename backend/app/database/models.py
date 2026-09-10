# ============================================================
# RYDEX - MODEL REGISTRATION
# ============================================================

# Users / Drivers
from app.users.models import User
from app.drivers.models import Driver

# Vehicles
from app.vehicles.models import Vehicle

# Rides
from app.rides.models import Ride

# Payments
from app.payments.models import Payment

# Ratings
from app.ratings.models import DriverRating

# Settings
from app.settings.models import (
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