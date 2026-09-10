from datetime import datetime, timezone
import os
import uuid

from fastapi import (
    APIRouter,
    Depends,
    File,
    HTTPException,
    UploadFile,
    status,
)
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.database.database import get_db
from app.users.models import User
from app.drivers.models import Driver
from app.drivers.schemas import (
    DriverRegister,
    DriverResponse,
    DriverStatusUpdate,
    DriverProfileResponse,
    DriverUpdate,
)
from app.drivers.location_models import DriverLocation
from app.drivers.location_schemas import (
    DriverLocationUpdate,
    DriverLocationResponse,
)
from app.rides.models import Ride
from app.notifications.websocket_manager import manager


router = APIRouter(
    prefix="/drivers",
    tags=["Drivers"],
)


# ============================================================
# CONSTANTS
# ============================================================

ALLOWED_IMAGE_TYPES = {
    "image/jpeg",
    "image/png",
    "image/webp",
}

MAX_FILE_SIZE = 10 * 1024 * 1024

UPLOAD_DIR = "app/uploads/drivers"
DOCUMENT_UPLOAD_DIR = "app/uploads/drivers/documents"


# ============================================================
# HELPER - GET CURRENT DRIVER
# ============================================================

def _get_driver(
    db: Session,
    current_user: User,
) -> Driver:
    driver = (
        db.query(Driver)
        .filter(Driver.user_id == current_user.id)
        .first()
    )

    if not driver:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Driver profile not found",
        )

    return driver


# ============================================================
# HELPER - SAVE IMAGE
# ============================================================

async def _save_image_file(
    file: UploadFile,
    upload_dir: str,
    filename_prefix: str,
) -> str:
    if file.content_type not in ALLOWED_IMAGE_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only JPG, PNG, and WEBP images are allowed",
        )

    if not file.filename:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid file",
        )

    if "." not in file.filename:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File must have an extension",
        )

    extension = file.filename.rsplit(".", 1)[1].lower()

    filename = f"{filename_prefix}_{uuid.uuid4()}.{extension}"

    os.makedirs(upload_dir, exist_ok=True)

    file_path = os.path.join(upload_dir, filename)

    content = await file.read()

    if not content:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Uploaded file is empty",
        )

    if len(content) > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File size must not exceed 10 MB",
        )

    with open(file_path, "wb") as buffer:
        buffer.write(content)

    return filename


# ============================================================
# REGISTER DRIVER
# ============================================================

@router.post(
    "/register",
    response_model=DriverResponse,
    status_code=status.HTTP_201_CREATED,
)
def register_driver(
    driver_data: DriverRegister,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    existing_driver = (
        db.query(Driver)
        .filter(Driver.user_id == current_user.id)
        .first()
    )

    if existing_driver:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You are already registered as a driver",
        )

    existing_license = (
        db.query(Driver)
        .filter(Driver.license_number == driver_data.license_number)
        .first()
    )

    if existing_license:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="License number is already registered",
        )

    new_driver = Driver(
        user_id=current_user.id,
        license_number=driver_data.license_number,
        is_verified=False,
        is_online=False,
    )

    db.add(new_driver)
    db.commit()
    db.refresh(new_driver)

    return new_driver


# ============================================================
# GET DRIVER PROFILE
# ============================================================

@router.get(
    "/profile",
    response_model=DriverProfileResponse,
)
def get_driver_profile(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    driver = _get_driver(db, current_user)

    return {
        "id": driver.id,
        "user_id": driver.user_id,
        "full_name": current_user.full_name,
        "phone_number": current_user.phone_number,
        "email": current_user.email,
        "license_number": driver.license_number,
        "vehicle_make": driver.vehicle_make,
        "vehicle_model": driver.vehicle_model,
        "vehicle_color": driver.vehicle_color,
        "vehicle_plate": driver.vehicle_plate,
        "profile_photo": driver.profile_photo,
        "vehicle_photo": driver.vehicle_photo,
        "driving_license_document": driver.driving_license_document,
        "national_id_document": driver.national_id_document,
        "vehicle_document": driver.vehicle_document,
        "is_verified": driver.is_verified,
        "is_online": driver.is_online,
    }


# ============================================================
# UPDATE DRIVER PROFILE
# ============================================================

@router.patch(
    "/profile",
    response_model=DriverResponse,
)
def update_driver_profile(
    profile_data: DriverUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    driver = _get_driver(db, current_user)

    if profile_data.vehicle_make is not None:
        driver.vehicle_make = profile_data.vehicle_make

    if profile_data.vehicle_model is not None:
        driver.vehicle_model = profile_data.vehicle_model

    if profile_data.vehicle_color is not None:
        driver.vehicle_color = profile_data.vehicle_color

    if profile_data.vehicle_plate is not None:
        existing_vehicle = (
            db.query(Driver)
            .filter(
                Driver.vehicle_plate == profile_data.vehicle_plate,
                Driver.id != driver.id,
            )
            .first()
        )

        if existing_vehicle:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Vehicle plate is already registered",
            )

        driver.vehicle_plate = profile_data.vehicle_plate

    db.commit()
    db.refresh(driver)

    return driver


# ============================================================
# UPDATE DRIVER ONLINE / OFFLINE STATUS
# ============================================================

@router.patch(
    "/status",
    response_model=DriverResponse,
)
def update_driver_status(
    status_data: DriverStatusUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    driver = _get_driver(db, current_user)

    if status_data.is_online and not driver.is_verified:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Driver must be verified before going online",
        )

    active_statuses = [
        "assigned",
        "accepted",
        "driver_arriving",
        "driver_arrived",
        "in_progress",
    ]

    active_ride = (
        db.query(Ride)
        .filter(
            Ride.driver_id == driver.id,
            Ride.status.in_(active_statuses),
        )
        .first()
    )

    if not status_data.is_online and active_ride:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You cannot go offline while you have an active ride.",
        )

    driver.is_online = status_data.is_online

    db.commit()
    db.refresh(driver)

    return driver


# ============================================================
# UPDATE DRIVER LOCATION
# ============================================================

@router.patch(
    "/location",
    response_model=DriverLocationResponse,
)
async def update_driver_location(
    location_data: DriverLocationUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    driver = _get_driver(db, current_user)

    if not driver.is_verified:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Driver is not verified",
        )

    if not driver.is_online:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Driver is offline",
        )

    now = datetime.now(timezone.utc)

    driver.latitude = location_data.latitude
    driver.longitude = location_data.longitude
    driver.location_updated_at = now

    location = (
        db.query(DriverLocation)
        .filter(DriverLocation.driver_id == driver.id)
        .first()
    )

    if location:
        location.latitude = location_data.latitude
        location.longitude = location_data.longitude
        location.updated_at = now
    else:
        location = DriverLocation(
            driver_id=driver.id,
            latitude=location_data.latitude,
            longitude=location_data.longitude,
        )
        db.add(location)

    db.commit()
    db.refresh(location)

    active_statuses = [
        "assigned",
        "accepted",
        "driver_arriving",
        "driver_arrived",
        "in_progress",
    ]

    active_ride = (
        db.query(Ride)
        .filter(
            Ride.driver_id == driver.id,
            Ride.status.in_(active_statuses),
        )
        .order_by(Ride.requested_at.desc())
        .first()
    )

    if active_ride:
        await manager.send_to_user(
            active_ride.passenger_id,
            {
                "type": "driver_location_update",
                "ride_id": active_ride.id,
                "driver_id": driver.id,
                "location": {
                    "latitude": location.latitude,
                    "longitude": location.longitude,
                },
                "timestamp": (
                    location.updated_at.isoformat()
                    if location.updated_at
                    else now.isoformat()
                ),
            },
        )

    return location


# ============================================================
# UPLOAD DRIVER PROFILE PHOTO
# ============================================================

@router.post("/profile/photo")
async def upload_profile_photo(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    driver = _get_driver(db, current_user)

    filename = await _save_image_file(
        file=file,
        upload_dir=UPLOAD_DIR,
        filename_prefix="profile",
    )

    profile_path = f"/uploads/drivers/{filename}"

    driver.profile_photo = profile_path

    db.commit()
    db.refresh(driver)

    return {
        "message": "Profile photo uploaded successfully",
        "profile_photo": profile_path,
    }


# ============================================================
# UPLOAD VEHICLE PHOTO
# ============================================================

@router.post("/vehicle/photo")
async def upload_vehicle_photo(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    driver = _get_driver(db, current_user)

    filename = await _save_image_file(
        file=file,
        upload_dir=UPLOAD_DIR,
        filename_prefix="vehicle",
    )

    vehicle_path = f"/uploads/drivers/{filename}"

    driver.vehicle_photo = vehicle_path

    db.commit()
    db.refresh(driver)

    return {
        "message": "Vehicle photo uploaded successfully",
        "vehicle_photo": vehicle_path,
    }


# ============================================================
# HELPER - SAVE VERIFICATION DOCUMENT
# ============================================================

async def _save_verification_document(
    file: UploadFile,
    document_type: str,
    driver: Driver,
    db: Session,
) -> str:
    allowed_documents = {
        "license": "driving_license_document",
        "national_id": "national_id_document",
        "vehicle": "vehicle_document",
    }

    if document_type not in allowed_documents:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid document type",
        )

    if file.content_type not in ALLOWED_IMAGE_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only JPG, PNG, and WEBP images are allowed",
        )

    if not file.filename:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid file",
        )

    if "." not in file.filename:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File must have an extension",
        )

    extension = file.filename.rsplit(".", 1)[1].lower()

    filename = f"{document_type}_{uuid.uuid4()}.{extension}"

    os.makedirs(DOCUMENT_UPLOAD_DIR, exist_ok=True)

    file_path = os.path.join(DOCUMENT_UPLOAD_DIR, filename)

    content = await file.read()

    if not content:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Uploaded file is empty",
        )

    if len(content) > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File size must not exceed 10 MB",
        )

    with open(file_path, "wb") as buffer:
        buffer.write(content)

    document_path = f"/uploads/drivers/documents/{filename}"

    column_name = allowed_documents[document_type]

    setattr(driver, column_name, document_path)

    db.commit()
    db.refresh(driver)

    return document_path


# ============================================================
# UPLOAD DRIVING LICENSE
# ============================================================

@router.post("/documents/license")
async def upload_driving_license_document(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    driver = _get_driver(db, current_user)

    document_path = await _save_verification_document(
        file=file,
        document_type="license",
        driver=driver,
        db=db,
    )

    return {
        "message": "Driving license uploaded successfully",
        "document_type": "license",
        "driving_license_document": document_path,
    }


# ============================================================
# UPLOAD NATIONAL ID
# ============================================================

@router.post("/documents/national-id")
async def upload_national_id_document(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    driver = _get_driver(db, current_user)

    document_path = await _save_verification_document(
        file=file,
        document_type="national_id",
        driver=driver,
        db=db,
    )

    return {
        "message": "National ID uploaded successfully",
        "document_type": "national_id",
        "national_id_document": document_path,
    }


# ============================================================
# UPLOAD VEHICLE DOCUMENT
# ============================================================

@router.post("/documents/vehicle")
async def upload_vehicle_document(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    driver = _get_driver(db, current_user)

    document_path = await _save_verification_document(
        file=file,
        document_type="vehicle",
        driver=driver,
        db=db,
    )

    return {
        "message": "Vehicle document uploaded successfully",
        "document_type": "vehicle",
        "vehicle_document": document_path,
    }


# ============================================================
# GET DRIVER LOCATION
# ============================================================

@router.get(
    "/{driver_id}/location",
    response_model=DriverLocationResponse,
)
def get_driver_location(
    driver_id: int,
    db: Session = Depends(get_db),
):
    location = (
        db.query(DriverLocation)
        .filter(DriverLocation.driver_id == driver_id)
        .first()
    )

    if not location:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Driver location not available",
        )

    return location
