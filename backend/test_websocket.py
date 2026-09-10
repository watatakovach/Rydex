import asyncio
import websockets


async def main():
    user_id = int(input("Driver user ID: ").strip())
    token = input("Driver JWT token: ").strip()

    url = (
        f"ws://127.0.0.1:8000"
        f"/notifications/ws/{user_id}"
        f"?token={token}"
    )

    print("\nConnecting...")

    try:
        async with websockets.connect(url) as websocket:
            print("✅ WebSocket connected!")
            print("Waiting for RYDEX notifications...\n")

            while True:
                message = await websocket.recv()
                print("🔔 NOTIFICATION RECEIVED:")
                print(message)
                print()

    except Exception as e:
        print(f"❌ WebSocket error: {e}")


if __name__ == "__main__":
    asyncio.run(main())