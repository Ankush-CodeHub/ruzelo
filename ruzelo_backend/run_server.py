import asyncio
import sys

# Crucial for Windows Python 3.10+ socket stability
if sys.platform == "win32":
    asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())

import uvicorn

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="127.0.0.1",
        port=8000,
        reload=False,
        loop="asyncio",
        log_level="info",
        access_log=True,
    )
