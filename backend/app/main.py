from fastapi import FastAPI

from app.database.connection import Base, engine
from app.users.models import User
from app.auth.router import router as auth_router
from app.users.router import router as users_router
from app.drivers.router import router as drivers_router
from app.vehicles.router import router as vehicles_router
from app.admin.router import router as admin_router
from app.rides.router import router as rides_router
from fastapi.middleware.cors import CORSMiddleware
from app.notifications.router import (
    router as websocket_router,
)

Base.metadata.create_all(bind=engine)


app = FastAPI(
    title="RYDEX API",
    description="RYDEX Ride-Hailing Platform API",
    version="1.0.0",
)
app.include_router(auth_router)
app.include_router(users_router)
app.include_router(drivers_router)
app.include_router(vehicles_router)
app.include_router(admin_router)
app.include_router(rides_router)
app.include_router(
    websocket_router
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)



@app.get("/")
def root():
    return {
        "message": "Welcome to RYDEX API",
        "status": "online",
        "version": "1.0.0",
    }


@app.get("/health")
def health_check():
    return {
        "status": "healthy"
    }