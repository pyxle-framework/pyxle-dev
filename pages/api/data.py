"""JSON data endpoint for benchmarking - matches Next.js /api/data."""

from __future__ import annotations

import time

from starlette.requests import Request
from starlette.responses import JSONResponse


async def endpoint(request: Request) -> JSONResponse:
    return JSONResponse({
        "version": "0.1.1",
        "features": [
            {"title": "File-Based Routing", "description": "Automatic routes from your file structure"},
            {"title": "Server Actions", "description": "Call server functions directly from React components"},
            {"title": "SSR Built-in", "description": "Server-side rendering with streaming support"},
            {"title": "Python + React", "description": "Colocate server logic and UI in .pyx files"},
        ],
        "stats": {"stars": 1200, "downloads": 45000, "contributors": 32},
        "timestamp": int(time.time() * 1000),
    })
