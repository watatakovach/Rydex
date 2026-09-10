from app.notifications.websocket_manager import manager


async def notify_ride_event(
    user_id: int,
    payload: dict,
):
    await manager.send_to_user(
        user_id,
        payload,
    )