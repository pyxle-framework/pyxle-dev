"""JSON data endpoint for benchmarking - matches Next.js /api/data."""

from __future__ import annotations

import time

from starlette.requests import Request
from starlette.responses import JSONResponse

from pyxle import __version__ as version


async def endpoint(request: Request) -> JSONResponse:
    return JSONResponse({
        "version": version,
        "features": [
            {"title": "File-Based Routing", "description": "Automatic routes from your file structure"},
            {"title": "Server Actions", "description": "Call server functions directly from React components"},
            {"title": "SSR Built-in", "description": "Server-side rendering with automatic hydration"},
            {"title": "Python + React", "description": "Colocate server logic and UI in .pyxl files"},
        ],
        "timestamp": int(time.time() * 1000),
    })
