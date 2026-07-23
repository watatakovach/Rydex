import asyncio
import websockets


async def main():
    uri = "ws://127.0.0.1:8000/ws/1"

    async with websockets.connect(uri) as websocket:
        print("Connected to RYDEX")

        await websocket.send(
            "Hello from RYDEX passenger"
        )

        response = await websocket.recv()

        print(
            "Server response:",
            response,
        )


asyncio.run(main())