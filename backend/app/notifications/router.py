from fastapi import (
    APIRouter,
    WebSocket,
    WebSocketDisconnect,
)

from app.notifications.websocket_manager import (
    manager,
)


router = APIRouter(
    prefix="/ws",
    tags=["WebSocket"],
)


@router.websocket("/{user_id}")
async def websocket_endpoint(
    websocket: WebSocket,
    user_id: int,
):
    await manager.connect(
        user_id,
        websocket,
    )

    try:
        while True:
            data = await websocket.receive_text()

            await websocket.send_json(
                {
                    "type": "connection",
                    "message": "RYDEX WebSocket connected",
                    "data": data,
                }
            )

    except WebSocketDisconnect:
        manager.disconnect(user_id)