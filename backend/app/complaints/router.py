from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user, require_admin
from app.database.database import get_db
from app.users.models import User
from app.complaints.models import Complaint
from app.complaints.schemas import (
    ComplaintCreate,
    ComplaintResponse,
    ComplaintStatusUpdate,
)

router = APIRouter(tags=["Complaints"])


# ============================================================
# USER ENDPOINTS
# ============================================================

@router.post(
    "/complaints",
    response_model=ComplaintResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_complaint(
    complaint_data: ComplaintCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    complaint = Complaint(
        user_id=current_user.id,
        ride_id=complaint_data.ride_id,
        title=complaint_data.title,
        description=complaint_data.description,
        status="pending",
    )
    db.add(complaint)
    db.commit()
    db.refresh(complaint)
    return complaint


@router.get(
    "/complaints/my",
    response_model=List[ComplaintResponse],
)
def get_my_complaints(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return (
        db.query(Complaint)
        .filter(Complaint.user_id == current_user.id)
        .order_by(Complaint.created_at.desc())
        .all()
    )


# ============================================================
# ADMIN ENDPOINTS
# ============================================================

@router.get(
    "/admin/complaints",
    response_model=List[ComplaintResponse],
)
def get_all_complaints_admin(
    status_filter: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    query = db.query(Complaint)
    if status_filter:
        query = query.filter(Complaint.status == status_filter)
    return query.order_by(Complaint.created_at.desc()).all()


@router.get(
    "/admin/users/{user_id}/complaints",
    response_model=List[ComplaintResponse],
)
def get_user_complaints_admin(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    return (
        db.query(Complaint)
        .filter(Complaint.user_id == user_id)
        .order_by(Complaint.created_at.desc())
        .all()
    )


@router.patch(
    "/admin/complaints/{complaint_id}/status",
    response_model=ComplaintResponse,
)
def update_complaint_status_admin(
    complaint_id: int,
    update_data: ComplaintStatusUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    complaint = (
        db.query(Complaint)
        .filter(Complaint.id == complaint_id)
        .first()
    )
    if not complaint:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Complaint not found",
        )

    complaint.status = update_data.status
    if update_data.admin_notes is not None:
        complaint.admin_notes = update_data.admin_notes

    db.commit()
    db.refresh(complaint)
    return complaint
