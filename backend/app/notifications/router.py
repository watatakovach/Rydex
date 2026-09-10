from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    WebSocket,
    WebSocketDisconnect,
    status,
)
from jose import JWTError, jwt
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.config import settings
from app.database.database import get_db
from app.notifications.models import Notification
from app.notifications.websocket_manager import manager
from app.notifications.schemas import (
    NotificationListResponse,
    NotificationResponse,
    NotificationUnreadCountResponse,
)
from app.users.models import User


router = APIRouter(
    prefix="/notifications",
    tags=["Notifications"],
)


# ============================================================
# GET MY NOTIFICATIONS
# ============================================================

@router.get(
    "",
    response_model=NotificationListResponse,
)
def get_my_notifications(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    notifications = (
        db.query(Notification)
        .filter(
            Notification.user_id == current_user.id
        )
        .order_by(
            Notification.created_at.desc()
        )
        .all()
    )

    unread = sum(
        1
        for notification in notifications
        if not notification.is_read
    )

    return NotificationListResponse(
        total=len(notifications),
        unread=unread,
        notifications=notifications,
    )


# ============================================================
# GET UNREAD NOTIFICATIONS
# ============================================================

@router.get(
    "/unread",
    response_model=NotificationListResponse,
)
def get_unread_notifications(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    notifications = (
        db.query(Notification)
        .filter(
            Notification.user_id == current_user.id,
            Notification.is_read.is_(False),
        )
        .order_by(
            Notification.created_at.desc()
        )
        .all()
    )

    return NotificationListResponse(
        total=len(notifications),
        unread=len(notifications),
        notifications=notifications,
    )


# ============================================================
# GET UNREAD COUNT
# ============================================================

@router.get(
    "/unread/count",
    response_model=NotificationUnreadCountResponse,
)
def get_unread_notification_count(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    unread = (
        db.query(Notification)
        .filter(
            Notification.user_id == current_user.id,
            Notification.is_read.is_(False),
        )
        .count()
    )

    return NotificationUnreadCountResponse(
        unread=unread,
    )


# ============================================================
# MARK NOTIFICATION AS READ
# ============================================================

@router.patch(
    "/{notification_id}/read",
)
def mark_notification_read(
    notification_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    notification = (
        db.query(Notification)
        .filter(
            Notification.id == notification_id,
            Notification.user_id == current_user.id,
        )
        .first()
    )

    if notification is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notification not found",
        )

    notification.is_read = True

    db.commit()
    db.refresh(notification)

    return {
        "message": "Notification marked as read",
        "notification": notification,
    }


# ============================================================
# MARK ALL AS READ
# ============================================================

@router.patch(
    "/read-all",
)
def mark_all_notifications_read(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    notifications = (
        db.query(Notification)
        .filter(
            Notification.user_id == current_user.id,
            Notification.is_read.is_(False),
        )
        .all()
    )

    for notification in notifications:
        notification.is_read = True

    db.commit()

    return {
        "message": "All notifications marked as read",
        "updated": len(notifications),
    }


# ============================================================
# WEBSOCKET AUTHENTICATION
# ============================================================

def authenticate_websocket(
    token: str,
    db: Session,
) -> User | None:
    try:
        payload = jwt.decode(
            token,
            settings.jwt_secret_key,
            algorithms=[settings.jwt_algorithm],
        )

        user_id = payload.get("sub")

        if user_id is None:
            return None

        user = (
            db.query(User)
            .filter(
                User.id == int(user_id),
                User.is_active.is_(True),
            )
            .first()
        )

        return user

    except (
        JWTError,
        ValueError,
        TypeError,
    ):
        return None


# ============================================================
# WEBSOCKET
# ============================================================

@router.websocket("/ws/{user_id}")
async def websocket_endpoint(
    websocket: WebSocket,
    user_id: int,
    db: Session = Depends(get_db),
):
    token = websocket.query_params.get("token")

    if not token:
        await websocket.close(
            code=1008,
            reason="Authentication required",
        )
        return

    user = authenticate_websocket(
        token,
        db,
    )

    if user is None:
        await websocket.close(
            code=1008,
            reason="Invalid authentication token",
        )
        return

    # IMPORTANT:
    # Never trust the user_id supplied in the URL.
    if user.id != user_id:
        await websocket.close(
            code=1008,
            reason="User ID does not match token",
        )
        return

    await manager.connect(
        user.id,
        websocket,
    )

    try:
        while True:
            await websocket.receive_text()

    except WebSocketDisconnect:
        manager.disconnect(
            user.id,
            websocket,
        )

    except Exception:
        manager.disconnect(
            user.id,
            websocket,
        )