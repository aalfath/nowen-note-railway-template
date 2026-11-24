[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/nowen-note-1?utm_medium=integration&utm_source=button&utm_campaign=nowen-note)

# Nowen Note on Railway

One-click Railway template for [Nowen Note](https://github.com/cropflre/nowen-note), an open-source, self-hosted notes app and knowledge base (rich text and Markdown, notebooks, tags, full-text search, mind maps, tasks, sharing, collaboration and an optional AI writing assistant).

- **Version:** Nowen Note v1.6.1, official image `cropflre/nowen-note:v1.6.1@sha256:f18f46c20e7d7046b6b26cf9e30257ece213ebe61859024363bd0e58d7c1dcb6`.
- **Service:** one service built from this repo's `Dockerfile`, port 3001, health check `/api/health`.
- **Storage:** a Railway volume at `/app/data` (SQLite database, attachments, JWT signing key, automatic backups).
- **RAM:** about 75 MB idle; fits Railway's 0.5 GB plan.

## Variables

| Variable | Default | What it does |
|---|---|---|
| `ADMIN_PASSWORD` | generated (`secret(24)`) | Password for the `admin` account, set on first boot only. Upstream's default `admin123` never reaches the public port. |
| `PUBLIC_WEB_ORIGIN` | `https://${{RAILWAY_PUBLIC_DOMAIN}}` | Public URL used in share links. Change it if you add a custom domain. |
| `PORT` | `3001` | Port the app listens on. |
| `AI_API_KEY` | empty (optional) | Key for any OpenAI-compatible API. If set, the admin's AI assistant is configured on the next start. |
| `AI_BASE_URL` | `https://api.openai.com/v1` | Base URL of that API (OpenRouter, DeepSeek, Groq, a self-hosted server...). |
| `AI_MODEL` | `gpt-4o-mini` | Model name for the AI assistant. |

## First start

1. Open the Railway domain and sign in as `admin` with the `ADMIN_PASSWORD` from the service's Variables tab.
2. Open sign-up is closed. Add users from the admin settings, or turn sign-up back on there.
3. Optional: set up the AI assistant in Settings > AI, or fill in `AI_API_KEY` and redeploy.

What the start script does on first boot: it starts Nowen Note once on an internal port, signs in with upstream's seeded `admin` / `admin123`, changes the password to `ADMIN_PASSWORD`, closes sign-up and checks that `admin123` no longer works. Only then does the app open the public port. If any step fails, the service exits with an error instead of running with the default password.

## Updates

Railway tells everyone who deployed this template when this repo's `main` branch changes. Each update bumps the pinned image in the `Dockerfile` and adds an entry to [`CHANGELOG.md`](CHANGELOG.md), with breaking changes first. Nowen Note migrates its database on start; back up first (Settings > Backups) before applying an update.

Not included: upstream's optional in-app updater container, which needs the Docker socket (not available on Railway).

## Licence

Nowen Note is GPL-3.0 (upstream). The files in this repo are a thin deployment wrapper.
