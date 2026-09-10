import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

sys.path.append(
    str(BASE_DIR.parent)
)

from logging.config import fileConfig

from alembic import context

from app.config import settings
# from app.database.database import Base, engine
from app.database.database import Base, engine

# Import ALL models here
from app.users.models import User
from app.drivers.models import Driver
from app.vehicles.models import Vehicle
from app.rides.models import Ride
from app.ratings.models import DriverRating
from app.drivers.location_models import DriverLocation
from app.notifications.models import Notification
from app.payments.models import Payment
from app.wallet.models import DriverWallet
from app.wallet.transaction_models import WalletTransaction
from app.admin.audit_models import AuditLog
from app.complaints.models import Complaint



config = context.config

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# Override the URL from alembic.ini with your .env value
config.set_main_option("sqlalchemy.url", settings.database_url)


# from app.settings.models import *
from app.settings.models.general import GeneralSettings
from app.settings.models.payment import PaymentSettings
from app.settings.models.ride import RideSettings
from app.settings.models.driver import DriverSettings
from app.settings.models.passenger import PassengerSettings
from app.settings.models.notification import NotificationSettings
from app.settings.models.map import MapSettings
from app.settings.models.security import SecuritySettings
from app.settings.models.analytics import AnalyticsSettings
from app.settings.models.backup import BackupSettings
from app.settings.models.appearance import AppearanceSettings
from app.settings.models.developer import DeveloperSettings

target_metadata = Base.metadata


def run_migrations_offline():
    context.configure(
        url=settings.database_url,
        target_metadata=target_metadata,
        literal_binds=True,
        compare_type=True,
    )

    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online():
    with engine.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
            compare_type=True,
        )

        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()