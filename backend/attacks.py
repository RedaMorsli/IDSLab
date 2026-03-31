import sys
import os
import asyncio
from server import send_progress


async def dos_slowloris(args={}):
    try:
        target_address = args['target_address']
        target_port = args['target_port']
        timeout = args['timeout']
        sockets = args['sockets']
        cmd = [sys.executable, "-u", os.path.join(os.path.dirname(__file__), "scripts", "slowloris.py"), target_address]
        if target_port:
            cmd.append("-p")
            cmd.append(str(target_port))
        if sockets:
            cmd.append('-s')
            cmd.append(str(int(sockets)))
        
        process = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.STDOUT
        )
        async def read_output():
            assert process.stdout is not None
            async for line in process.stdout:
                print(f"[output] {line.decode().strip()}")
                await send_progress(args['ws'], args['request_id'], {'output': line.decode().strip()})
        
        await asyncio.wait_for(
            asyncio.gather(read_output(), process.wait()),
            timeout=timeout
        )
    except asyncio.TimeoutError:
        print("Process timed out. Terminating...")
        process.kill()
        await process.wait()
