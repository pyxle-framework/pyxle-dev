from starlette.requests import Request
from pyxle.runtime import server
import re as _re
from pyxle import __version__
from pyxle.runtime import ActionError

HEAD = [
    '<title>Pyxle - Python-First Full-Stack Framework</title>',
    '<meta name="description" content="Build like Next.js without leaving Python. Colocate server loaders and React components in .pyx files." />',
    '<meta name="viewport" content="width=device-width, initial-scale=1" />',
    '<link rel="icon" href="/favicon.svg" type="image/svg+xml" />',
    '<link rel="preconnect" href="https://fonts.googleapis.com" />',
    '<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />',
    '<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&amp;family=JetBrains+Mono:wght@400;500&amp;display=swap" rel="stylesheet" />',
    '<link rel="stylesheet" href="/styles/tailwind.css" />',
    '<meta property="og:title" content="Pyxle - Python-First Full-Stack Framework" />',
    '<meta property="og:description" content="Build like Next.js without leaving Python." />',
    '<script src="/scripts/analytics.js" defer></script>',
]

_EMAIL_RE = _re.compile(r"^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$")


@server
async def load_home(request: Request):
    return {
        "version": __version__,
    }


@action
async def subscribe_newsletter(request: Request):
    import sys, os
    sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
    from db import add_subscriber

    body = await request.json()
    email = (body.get("email") or "").strip().lower()

    if not email:
        raise ActionError("Please enter your email address.", status_code=400)

    if not _EMAIL_RE.match(email):
        raise ActionError("Please enter a valid email address.", status_code=400)

    if len(email) > 254:
        raise ActionError("Email address is too long.", status_code=400)

    add_subscriber(email)
    return {"message": "You're on the list! We'll keep you posted."}


