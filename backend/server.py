import asyncio
import websockets
import json
import dispatcher
from db import init_database


async def handler(websocket):
    async for message in websocket:
        try:
            request = json.loads(message)
            print(request)
            request_id = request.get("request_id")
            command = request.get("command")
            args = request.get("args", {})
            if args == None:
                args = {}
            args['request_id'] = request_id
            args['ws'] = websocket

            response = await dispatcher.dispatch(command, args)
        except Exception as e:
            response = {"request_id": request_id, "status": "error", "message": str(e)}

        await websocket.send(json.dumps(response))


async def send_progress(ws, request_id: int, progress: dict = {}):
    response = {}
    response['request_id'] = request_id
    response['status'] = 'progress'
    response['data'] = progress
    await ws.send(json.dumps(response))


async def main():
    async with websockets.serve(lambda ws: handler(ws), "0.0.0.0", 8765):
        print("WebSocket server started on ws://0.0.0.0:8765")
        await asyncio.Future()


if __name__ == "__main__":
    init_database()
    asyncio.run(main())
