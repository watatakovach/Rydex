import uuid

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from sqlalchemy.orm import Session, selectinload

from app.auth.dependencies import require_role
from app.config import UPLOAD_DIR
from app.database.connection import get_db
from app.drivers.models import Driver
from app.users.models import User
from app.vehicles.models import Vehicle, VehicleImage
from app.vehicles.schemas import VehicleImageResponse, VehicleWithImagesResponse


router = APIRouter(prefix="/admin", tags=["Admin"])

MAX_IMAGE_BYTES = 5 * 1024 * 1024
MAX_IMAGES_PER_UPLOAD = 10


def _image_extension(data: bytes) -> str | None:
    # Trust the file's magic bytes, not the client-supplied name or content type
    if data.startswith(b"\xff\xd8\xff"):
        return "jpg"
    if data.startswith(b"\x89PNG\r\n\x1a\n"):
        return "png"
    if data[:4] == b"RIFF" and data[8:12] == b"WEBP":
        return "webp"
    return None


@router.get("/drivers")
def list_drivers(
    _: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    return db.query(Driver).order_by(Driver.created_at.desc()).all()


@router.get("/drivers/pending")
def pending_drivers(
    _: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    return db.query(Driver).filter(Driver.is_verified.is_(False)).all()


@router.patch("/drivers/{driver_id}/verify")
def verify_driver(
    driver_id: int,
    _: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    driver = db.get(Driver, driver_id)
    if not driver:
        raise HTTPException(404, "Driver not found")

    driver.is_verified = True
    db.commit()
    db.refresh(driver)
    return {
        "message": "Driver verified successfully",
        "driver_id": driver.id,
        "is_verified": driver.is_verified,
    }


@router.patch("/drivers/{driver_id}/unverify")
def unverify_driver(
    driver_id: int,
    _: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    driver = db.get(Driver, driver_id)
    if not driver:
        raise HTTPException(404, "Driver not found")

    driver.is_verified = False
    driver.is_online = False
    db.commit()
    return {"message": "Driver verification revoked", "driver_id": driver.id}


@router.get("/vehicles", response_model=list[VehicleWithImagesResponse])
def list_vehicles(
    _: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    return (
        db.query(Vehicle)
        .options(selectinload(Vehicle.images))
        .order_by(Vehicle.id.desc())
        .all()
    )


@router.get("/vehicles/{vehicle_id}", response_model=VehicleWithImagesResponse)
def get_vehicle(
    vehicle_id: int,
    _: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    vehicle = db.get(Vehicle, vehicle_id)
    if not vehicle:
        raise HTTPException(404, "Vehicle not found")
    return vehicle


@router.post(
    "/vehicles/{vehicle_id}/images",
    response_model=list[VehicleImageResponse],
    status_code=201,
)
async def upload_vehicle_images(
    vehicle_id: int,
    files: list[UploadFile] = File(...),
    _: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    vehicle = db.get(Vehicle, vehicle_id)
    if not vehicle:
        raise HTTPException(404, "Vehicle not found")

    if len(files) > MAX_IMAGES_PER_UPLOAD:
        raise HTTPException(400, f"You can upload at most {MAX_IMAGES_PER_UPLOAD} images at a time")

    # Validate every file before writing anything, so a bad file rejects the whole batch
    validated: list[tuple[bytes, str]] = []
    for f in files:
        data = await f.read(MAX_IMAGE_BYTES + 1)
        if len(data) > MAX_IMAGE_BYTES:
            raise HTTPException(400, f"{f.filename} is larger than 5 MB")
        ext = _image_extension(data)
        if not ext:
            raise HTTPException(400, f"{f.filename} is not a JPG, PNG or WebP image")
        validated.append((data, ext))

    vehicle_dir = UPLOAD_DIR / "vehicles" / str(vehicle_id)
    vehicle_dir.mkdir(parents=True, exist_ok=True)

    written = []
    images = []
    try:
        for data, ext in validated:
            name = f"{uuid.uuid4().hex}.{ext}"
            path = vehicle_dir / name
            path.write_bytes(data)
            written.append(path)
            image = VehicleImage(vehicle_id=vehicle_id, file_path=f"vehicles/{vehicle_id}/{name}")
            db.add(image)
            images.append(image)
        db.commit()
    except Exception:
        db.rollback()
        for path in written:
            path.unlink(missing_ok=True)
        raise

    for image in images:
        db.refresh(image)
    return images


@router.delete("/vehicles/{vehicle_id}/images/{image_id}")
def delete_vehicle_image(
    vehicle_id: int,
    image_id: int,
    _: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    image = db.get(VehicleImage, image_id)
    if not image or image.vehicle_id != vehicle_id:
        raise HTTPException(404, "Image not found")

    path = UPLOAD_DIR / image.file_path
    db.delete(image)
    db.commit()
    path.unlink(missing_ok=True)
    return {"message": "Image deleted", "image_id": image_id}
