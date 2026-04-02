# CLAUDE.md — Pyxle Dev Site

This is the repository for the [pyxle.dev](https://pyxle.dev) website.
It is a Pyxle application that showcases the framework's features.

## Related Repositories

- `pyxle` — Core framework (this app is built with it)
- `pyxle-langkit` — Language tools and IDE support
- `pyxle-plugins` — Official Pyxle plugins

---

## Running the Dev Site

```bash
# Install dependencies
pip install pyxle-framework
npm install

# Start the dev server
pyxle dev                  # http://localhost:8000
```

## Project Structure

```
pages/                     # File-based routes
|-- index.pyx              # Home page
|-- layout.pyx             # Root layout
|-- not-found.pyx          # 404 page
|-- api/                   # API routes
|   |-- healthz.py         # Health check
|   +-- subscribers.py     # Admin panel (requires PYXLE_ADMIN_PASSWORD env var)
+-- styles/
    +-- tailwind.css        # Tailwind entry point

public/                    # Static assets
|-- favicon.svg
|-- branding/              # Pyxle logos and marks
+-- styles/

data/                      # Application data (gitignored)
db.py                      # Database utilities
pyxle.config.json          # Pyxle configuration
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `PYXLE_ADMIN_USERNAME` | No | Admin panel username (default: `admin`) |
| `PYXLE_ADMIN_PASSWORD` | Yes | Admin panel password. Must be set for `/api/subscribers` to work. |

## Rules

- Follow Pyxle conventions for `.pyx` files (server loaders, actions, JSX)
- Keep the site clean and representative of Pyxle best practices
- Test changes with `pyxle dev` before committing
- Never commit `data/`, `.env`, or `DEPLOYMENT.md`
