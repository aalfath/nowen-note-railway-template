# Changelog

Deployers read this before they apply a Railway update. Breaking changes are listed first in each entry.

## v1.6.1-railway.1 (2026-11-24)

- First release of the Railway template.
- Nowen Note v1.6.1, official image `cropflre/nowen-note:v1.6.1@sha256:f18f46c20e7d7046b6b26cf9e30257ece213ebe61859024363bd0e58d7c1dcb6`.
- All data (SQLite database, attachments, JWT secret, backups) on the Railway volume at `/app/data`.
- First boot replaces upstream's default `admin` / `admin123` with the generated `ADMIN_PASSWORD` and closes open sign-up before the public port opens.
- Optional `AI_API_KEY` / `AI_BASE_URL` / `AI_MODEL` pre-configure the admin's AI assistant (any OpenAI-compatible API).
- Left out: upstream's optional `nowen-note-updater` container (it needs the Docker socket, which Railway doesn't provide).
