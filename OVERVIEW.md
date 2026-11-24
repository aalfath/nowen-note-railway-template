# Deploy and Host Nowen Note on Railway

Nowen Note is an open-source, self-hosted notes app and private knowledge base. It combines rich-text and Markdown notes in one notebook tree with tags, full-text search, mind maps, tasks and a calendar, sharing and real-time collaboration, version history, backups, and an optional AI writing assistant that works with any OpenAI-compatible API.

## About Hosting Nowen Note

This template runs the official Nowen Note v1.6.1 image (pinned by digest) as one Railway service with a public HTTPS domain and a volume at `/app/data` that holds the SQLite database, attachments, the JWT signing key and automatic backups. Upstream seeds an `admin` / `admin123` account; on first boot this template replaces that password with a generated one and closes open sign-up before the public port opens. After deploy, open the domain and sign in as `admin` with the `ADMIN_PASSWORD` shown in the service's Variables tab. To update, apply the update Railway offers when this template's repo moves to a new Nowen Note release.

## Common Use Cases

* A private, Notion-style notebook and personal knowledge base that you own
* A small team wiki with shared notebooks, comments and real-time co-editing
* Drafting, summarising and searching notes with your own AI provider's key

## Dependencies for Nowen Note Hosting

* One Railway service built from the template repo (official `cropflre/nowen-note` image)
* One Railway volume for the database, attachments and backups

### Deployment Dependencies

* Nowen Note source and docs: https://github.com/cropflre/nowen-note
* Release v1.6.1: https://github.com/cropflre/nowen-note/releases/tag/v1.6.1
* Template repo (Dockerfile, start script, changelog): https://github.com/aalfath/nowen-note-railway-template

### Implementation Details

Services and variables:

* `Nowen Note`: the web app and API on port 3001, health check `/api/health`, volume `/app/data`.
* `ADMIN_PASSWORD`: generated on deploy; the password for the `admin` account. Changing it later in the app is fine; the variable is only used on first boot.
* `PUBLIC_WEB_ORIGIN`: set to your Railway domain so share links point at it. Change it if you add a custom domain.
* `AI_API_KEY` (optional), `AI_BASE_URL` (default `https://api.openai.com/v1`) and `AI_MODEL` (default `gpt-4o-mini`): fill in the key to pre-configure the admin's AI assistant on the next start. Any OpenAI-compatible API works (OpenRouter, DeepSeek, Groq, a self-hosted server). You can also leave them empty and set AI per user in Settings > AI.

After deploy: sign in as `admin`, then add users from the admin settings or turn sign-up back on there if you want self-registration. Users can enable two-factor sign-in under account security. Automatic backups (database only, daily, 15 kept) go to the same volume, so download one now and then from Settings > Backups.

Left out on purpose: upstream's optional in-app updater container, because it needs the Docker socket, which Railway doesn't provide. Updates come from this template's repo instead. Nowen Note idles at about 75 MB of RAM and fits Railway's smallest plan (0.5 GB).

## Why Deploy Nowen Note on Railway?

<!-- Recommended: Keep this section as shown below -->
Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying Nowen Note on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
<!-- End recommended section -->
