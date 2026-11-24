#!/bin/sh
# Railway start script for Nowen Note.
# 1. Keeps all state on the Railway volume at /app/data.
# 2. On first boot, starts the app once on an internal port (the public port is
#    still closed), replaces upstream's default admin password "admin123" with
#    ADMIN_PASSWORD and closes open sign-up. If that fails, it exits non-zero, so
#    the app never serves the public port with the default password.
# 3. Optionally seeds the admin's AI assistant settings from AI_API_KEY.
# 4. Hands over to upstream's entrypoint (JWT secret on the volume, schema check).
set -eu

DATA_DIR=/app/data
mkdir -p "$DATA_DIR"
cd /app

PUBLIC_PORT="${PORT:-3001}"
BOOT_PORT="${RAILWAY_BOOTSTRAP_PORT:-3999}"
export DB_PATH="${DB_PATH:-$DATA_DIR/nowen-note.db}"

# PUBLIC_WEB_ORIGIN comes from https://${{RAILWAY_PUBLIC_DOMAIN}}; drop it if the
# domain did not exist yet (value "https://") so share links fall back to the
# request origin instead of a broken URL.
case "${PUBLIC_WEB_ORIGIN:-}" in
  http://?*.?*|https://?*.?*) export PUBLIC_WEB_ORIGIN ;;
  *) unset PUBLIC_WEB_ORIGIN ;;
esac

# Size the Node heap from the container's memory limit (cgroup v2 or v1).
if [ -z "${NODE_OPTIONS:-}" ]; then
  LIM=""
  [ -r /sys/fs/cgroup/memory.max ] && LIM="$(cat /sys/fs/cgroup/memory.max)"
  [ -z "$LIM" ] && [ -r /sys/fs/cgroup/memory/memory.limit_in_bytes ] && LIM="$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes)"
  case "$LIM" in
    ''|max) ;;
    *[!0-9]*) ;;
    *)
      MB=$((LIM / 1048576))
      if [ "$MB" -gt 0 ] && [ "$MB" -lt 65536 ]; then
        HEAP=$((MB * 60 / 100))
        [ "$HEAP" -lt 160 ] && HEAP=160
        export NODE_OPTIONS="--max-old-space-size=$HEAP"
        echo "[railway] memory limit ${MB} MB, Node heap capped at ${HEAP} MB"
      fi ;;
  esac
fi

BOOT_MARK="$DATA_DIR/.railway-admin-bootstrapped"
AI_MARK="$DATA_DIR/.railway-ai-seeded"

need_boot=0
[ -f "$BOOT_MARK" ] || need_boot=1
if [ -n "${AI_API_KEY:-}" ] && [ ! -f "$AI_MARK" ]; then need_boot=1; fi

if [ "$need_boot" = 1 ]; then
  if [ ! -f "$BOOT_MARK" ]; then
    case "${ADMIN_PASSWORD:-}" in
      ''|admin123) echo "[railway] ADMIN_PASSWORD is empty or the upstream default; refusing to start." >&2; exit 1 ;;
    esac
    if [ "$(printf %s "$ADMIN_PASSWORD" | wc -c)" -lt 12 ]; then
      echo "[railway] ADMIN_PASSWORD must be at least 12 characters; refusing to start." >&2; exit 1
    fi
  fi
  echo "[railway] one-off setup: starting Nowen Note on internal port $BOOT_PORT"
  PORT="$BOOT_PORT" /usr/local/bin/docker-entrypoint.sh node backend/dist/index.hardened.js >/tmp/railway-bootstrap-app.log 2>&1 &
  APP_PID=$!
  rc=0
  BOOT_PORT="$BOOT_PORT" BOOT_MARK="$BOOT_MARK" AI_MARK="$AI_MARK" node /railway/railway-bootstrap.mjs || rc=$?
  kill -TERM "$APP_PID" 2>/dev/null || true
  i=0
  while kill -0 "$APP_PID" 2>/dev/null && [ "$i" -lt 30 ]; do sleep 0.5; i=$((i + 1)); done
  kill -KILL "$APP_PID" 2>/dev/null || true
  wait "$APP_PID" 2>/dev/null || true
  if [ "$rc" -ne 0 ]; then
    echo "[railway] setup failed (exit $rc); last lines of the setup instance log:" >&2
    tail -n 30 /tmp/railway-bootstrap-app.log >&2 || true
    exit "$rc"
  fi
fi

echo "[railway] starting Nowen Note on port $PUBLIC_PORT"
export PORT="$PUBLIC_PORT"
exec /usr/local/bin/docker-entrypoint.sh "$@"
