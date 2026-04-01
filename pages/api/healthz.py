from __future__ import annotations

from starlette.requests import Request
from starlette.responses import JSONResponse


async def endpoint(request: Request) -> JSONResponse:
    return JSONResponse({"status": "ok"})
