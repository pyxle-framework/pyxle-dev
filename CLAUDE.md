# CLAUDE.md — pyxle.dev Development Guide

This file instructs Claude (and any AI agent) on how to work on the pyxle.dev website.
This is a real Pyxle application — treat it as a reference implementation of the framework.

## Related Repositories

- [`pyxle`](https://github.com/shivamsn97/pyxle) — Core framework (this app is built with it)
- `pyxle-langkit` — Language tools and IDE support
- `pyxle-plugins` — Official Pyxle plugins

---

## Project Overview

This is the source for [pyxle.dev](https://pyxle.dev), the official Pyxle marketing site.
It uses `.pyx` files with `@server` loaders, `@action` mutations, Tailwind CSS, and
file-based routing — everything the framework offers.

**Key files to read first:**
- `pages/index.pyx` — Home page with `@server` loader, `@action` newsletter subscription, and full React UI
- `pages/layout.pyx` — Root layout with theme toggle (dark/light)
- `pages/not-found.pyx` — Custom 404 page
- `db.py` — SQLite subscriber storage
- `pyxle.config.json` — Framework configuration

---

## Running Locally

```bash
pip install pyxle-framework
npm install
pyxle dev
```

Open http://localhost:8000.

---

## Mandatory Rules

### 1. Test Every Change Locally

Run `pyxle dev` and verify in the browser before committing. This site is live
at pyxle.dev — broken commits break the public website.

### 2. Follow Pyxle Conventions

This site should be a showcase of best practices:
- `@server` for data loading, `@action` for mutations
- HEAD variable for static meta tags
- Tailwind CSS for styling
- File-based routing under `pages/`

### 3. Never Commit Secrets or Data

- **DO NOT** commit `data/` (contains subscriber emails — gitignored)
- **DO NOT** commit `.env` files
- **DO NOT** commit `DEPLOYMENT.md` (contains server credentials — gitignored)
- **DO NOT** hardcode passwords, tokens, or API keys in source files
- Use environment variables for all secrets (see table below)

### 4. Commit Style

Follow Conventional Commits: `feat`, `fix`, `chore`, `docs`, `style`.

Do **not** add `Co-Authored-By` trailers or AI attribution to commit messages.

---

## Project Structure

```
pages/                     # File-based routes
|-- index.pyx              # Home page (@server loader + @action subscribe)
|-- layout.pyx             # Root layout (theme context, dark/light toggle)
|-- not-found.pyx          # 404 page
|-- api/                   # API routes (plain Starlette endpoints)
|   |-- healthz.py         # Health check — GET /api/healthz
|   +-- subscribers.py     # Admin panel — GET /api/subscribers (HTTP Basic Auth)
+-- styles/
    +-- tailwind.css        # Tailwind entry point

public/                    # Static assets (served at /)
|-- favicon.svg            # Site favicon (Pyxle mark)
|-- branding/              # Logos: mark, wordmark (dark/light), grid pattern
+-- styles/
    +-- tailwind.css        # Compiled Tailwind output

db.py                      # SQLite subscriber storage (add, exists, count, list)
data/                      # Runtime database directory (gitignored)
pyxle.config.json          # Pyxle configuration
package.json               # Node dependencies (Vite, React, Tailwind)
requirements.txt           # Python dependencies
tailwind.config.cjs        # Tailwind configuration
postcss.config.cjs         # PostCSS configuration
```

---

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `PYXLE_ADMIN_USERNAME` | No | Admin panel username (default: `admin`) |
| `PYXLE_ADMIN_PASSWORD` | **Yes** | Admin panel password. Endpoint returns 401 if unset. |

---

## Key Patterns

### Newsletter Subscription (`pages/index.pyx`)

The subscribe flow demonstrates Pyxle's `@action` pattern:
1. `@action subscribe_newsletter(request)` validates and stores the email via `db.py`
2. Client calls it with `useAction("subscribe_newsletter")` from `pyxle/client`
3. Returns `ActionError` for validation failures, JSON for success

### Admin Panel (`pages/api/subscribers.py`)

A plain Starlette endpoint (not a `.pyx` page) that:
- Requires HTTP Basic Auth via `PYXLE_ADMIN_PASSWORD` env var
- Returns an HTML table at `/api/subscribers`
- Returns CSV at `/api/subscribers?format=csv`

### Theme System (`pages/layout.pyx`)

Root layout provides a `ThemeContext` with `useTheme()` hook.
Theme preference is stored in `localStorage` and applied as a CSS class on `<html>`.

---

## Deployment

The site is deployed on EC2 behind Cloudflare. See `DEPLOYMENT.md` (gitignored, local only)
for server details. Quick deploy:

```bash
pyxle build
pyxle serve --host 127.0.0.1 --port 8000 --skip-build
```

Health check: `GET /api/healthz` → `{"status":"ok"}`

---

## DO NOT List

- **DO NOT** commit `data/`, `.env`, or `DEPLOYMENT.md`
- **DO NOT** hardcode secrets in source files — use environment variables
- **DO NOT** add `Co-Authored-By` or AI attribution to commit messages
- **DO NOT** break the subscribe flow without testing end-to-end
- **DO NOT** remove or weaken the HTTP Basic Auth on the admin panel
- **DO NOT** expose subscriber emails in client-side code or public endpoints
