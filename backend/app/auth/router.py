from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.auth.schemas import TokenResponse, UserRegister, UserResponse
from app.auth.security import create_access_token, hash_password, verify_password
from app.database.connection import get_db
from app.users.models import User


router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", response_model=UserResponse, status_code=201)
def register_user(user_data: UserRegister, db: Session = Depends(get_db)):
    if db.query(User).filter(User.phone_number == user_data.phone_number).first():
        raise HTTPException(400, "Phone number is already registered")

    if user_data.email and db.query(User).filter(User.email == user_data.email).first():
        raise HTTPException(400, "Email is already registered")

    user = User(
        full_name=user_data.full_name,
        phone_number=user_data.phone_number,
        email=str(user_data.email) if user_data.email else None,
        password_hash=hash_password(user_data.password),
        role="passenger",
        is_active=True,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@router.post("/login", response_model=TokenResponse)
def login_user(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db),
):
    user = db.query(User).filter(
        or_(
            User.email == form_data.username,
            User.phone_number == form_data.username,
        )
    ).first()

    if not user or not verify_password(form_data.password, user.password_hash):
        raise HTTPException(
            status_code=401,
            detail="Invalid email/phone number or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not user.is_active:
        raise HTTPException(403, "User account is inactive")

    token = create_access_token({"sub": str(user.id), "role": user.role})
    return {"access_token": token, "token_type": "bearer"}


@router.patch("/make-admin")
def make_current_user_admin(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    current_user.role = "admin"
    db.commit()
    db.refresh(current_user)
    return {"message": "User promoted to admin", "user_id": current_user.id, "role": current_user.role}
