from sqlalchemy.orm import Session

from app.notifications.models import Notification
from app.notifications.websocket_manager import manager


async def create_notification(
    db: Session,
    user_id: int,
    notification_type: str,
    title: str,
    message: str,
    entity_type: str | None = None,
    entity_id: int | None = None,
    data: dict | None = None,
):
    """
    Creates a persistent notification and immediately
    delivers it through WebSocket when the user is online.
    """

    notification = Notification(
        user_id=user_id,
        type=notification_type,
        title=title,
        message=message,
        entity_type=entity_type,
        entity_id=entity_id,
        data=data,
        is_read=False,
    )

    db.add(notification)
    db.commit()
    db.refresh(notification)

    payload = {
        "type": "notification",
        "notification": {
            "id": notification.id,
            "user_id": notification.user_id,
            "type": notification.type,
            "title": notification.title,
            "message": notification.message,
            "entity_type": notification.entity_type,
            "entity_id": notification.entity_id,
            "data": notification.data,
            "is_read": notification.is_read,
            "created_at": (
                notification.created_at.isoformat()
                if notification.created_at
                else None
            ),
        },
    }

    await manager.send_to_user(
        user_id,
        payload,
    )

    return notification