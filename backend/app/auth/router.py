from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from app.auth.dependencies import get_current_user

from app.auth.schemas import (
    TokenResponse,
    UserRegister,
    UserResponse,
)
from app.auth.security import (
    create_access_token,
    hash_password,
    verify_password,
)
from app.database.connection import get_db
from app.users.models import User


router = APIRouter(
    prefix="/auth",
    tags=["Authentication"],
)


@router.post(
    "/register",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED,
)
def register_user(
    user_data: UserRegister,
    db: Session = Depends(get_db),
):
    # Check if phone number already exists
    existing_phone = (
        db.query(User)
        .filter(
            User.phone_number == user_data.phone_number
        )
        .first()
    )

    if existing_phone:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Phone number is already registered",
        )

    # Check if email already exists
    if user_data.email:
        existing_email = (
            db.query(User)
            .filter(
                User.email == user_data.email
            )
            .first()
        )

        if existing_email:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email is already registered",
            )

    # Create new passenger
    new_user = User(
        full_name=user_data.full_name,
        phone_number=user_data.phone_number,
        email=user_data.email,
        password_hash=hash_password(
            user_data.password
        ),
        role="passenger",
        is_active=True,
    )

    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    return new_user


@router.post(
    "/login",
    response_model=TokenResponse,
)
def login_user(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db),
):
    # Allow login using either email or phone number
    user = (
        db.query(User)
        .filter(
            (User.email == form_data.username)
            | (User.phone_number == form_data.username)
        )
        .first()
    )

    # User not found
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email/phone number or password",
            headers={
                "WWW-Authenticate": "Bearer"
            },
        )

    # Verify password
    if not verify_password(
        form_data.password,
        user.password_hash,
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email/phone number or password",
            headers={
                "WWW-Authenticate": "Bearer"
            },
        )

    # Check if account is active
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User account is inactive",
        )

    # Create JWT access token
    access_token = create_access_token(
        data={
            "sub": str(user.id),
            "role": user.role,
        }
    )

    return {
        "access_token": access_token,
        "token_type": "bearer",
    }



@router.patch("/make-admin")
def make_current_user_admin(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    current_user.role = "admin"

    db.commit()
    db.refresh(current_user)

    return {
        "message": "User promoted to admin",
        "user_id": current_user.id,
        "role": current_user.role,
    }