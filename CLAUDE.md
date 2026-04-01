# CLAUDE.md — Pyxle Dev Site

This is the **private** repository for the [pyxle.dev](https://pyxle.dev) website.
It is a Pyxle application that showcases the framework's features.

## Related Repositories

- `pyxle` — Core framework (this app is built with it)
- `pyxle-langkit` — Language tools and IDE support
- `pyxle-plugins` — Official Pyxle plugins

---

## Running the Dev Site

```bash
# Install dependencies
pip install pyxle          # or pip install -e /path/to/pyxle for local dev
npm install

# Start the dev server
pyxle dev                  # http://localhost:3000
```

## Project Structure

```
pages/                     # File-based routes
|-- index.pyx              # Home page
|-- layout.pyx             # Root layout
|-- not-found.pyx          # 404 page
|-- api/                   # API routes
|   |-- pulse.py           # Health/status endpoint
|   +-- healthz.py         # Health check
+-- styles/
    +-- tailwind.css        # Tailwind entry point

public/                    # Static assets
|-- favicon.ico
|-- branding/              # Pyxle logos and marks
+-- styles/

data/                      # Application data
db.py                      # Database utilities
pyxle.config.json          # Pyxle configuration
```

## Rules

- This is a **private** repository -- do not publish or expose publicly
- Follow Pyxle conventions for `.pyx` files (server loaders, actions, JSX)
- Keep the site clean and representative of Pyxle best practices
- Test changes with `pyxle dev` before committing
