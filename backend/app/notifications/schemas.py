from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict


class NotificationResponse(BaseModel):
    id: int
    user_id: int
    type: str
    title: str
    message: str

    entity_type: str | None = None
    entity_id: int | None = None

    data: dict[str, Any] | None = None

    is_read: bool
    created_at: datetime

    model_config = ConfigDict(
        from_attributes=True
    )


class NotificationListResponse(BaseModel):
    total: int
    unread: int
    notifications: list[NotificationResponse]


class NotificationUnreadCountResponse(BaseModel):
    unread: int