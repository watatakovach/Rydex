from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware

from app.database.database import Base, engine
from app.users.models import User


from app.auth.router import router as auth_router
from app.users.router import router as users_router
from app.drivers.router import router as drivers_router
from app.vehicles.router import router as vehicles_router
from app.admin.router import router as admin_router
from app.admin.super_admin_router import router as super_admin_router
from app.rides.router import router as rides_router
from app.payments.router import router as payments_router
from app.ratings.models import DriverRating
from app.ratings.router import router as ratings_router
from app.settings.router import router as settings_router

from app.database.database import SessionLocal
from app.settings.seeder import seed_settings

from app.notifications.router import (
    router as notifications_router,
)
from app.complaints.router import router as complaints_router
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

# ============================================================
# DATABASE
# ============================================================

Base.metadata.create_all(bind=engine)


# ============================================================
# FASTAPI APPLICATION
# ============================================================

app = FastAPI(
    title="RYDEX API",
    description="RYDEX Ride-Hailing Platform API",
    version="1.0.0",
)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============================================================
# SERVE UPLOADED FILES
# ============================================================

app.mount(
    "/uploads",
    StaticFiles(directory="app/uploads"),
    name="uploads",
)


# ============================================================
# API ROUTERS
# ============================================================

app.include_router(auth_router)
app.include_router(users_router)
app.include_router(drivers_router)
app.include_router(vehicles_router)
app.include_router(admin_router)
app.include_router(super_admin_router)
app.include_router(rides_router)
app.include_router(notifications_router)
app.include_router(payments_router)
app.include_router(complaints_router)
app.include_router(ratings_router)
app.include_router(settings_router)





# ============================================================
# ROOT
# ============================================================

@app.get("/")
def root():
    return {
        "message": "Welcome to RYDEX API",
        "status": "online",
        "version": "1.0.0",
    }


# ============================================================
# HEALTH CHECK
# ============================================================

@app.get("/health")
def health_check():
    return {
        "status": "healthy"
    }

@app.on_event("startup")
def startup_event():

    db = SessionLocal()

    try:

        seed_settings(db)

    finally:

        db.close()