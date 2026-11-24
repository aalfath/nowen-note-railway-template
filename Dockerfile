# Nowen Note for Railway: the official upstream image, pinned by version and digest.
# Bump the tag and digest together, and add a CHANGELOG.md entry.
FROM cropflre/nowen-note:v1.6.1@sha256:f18f46c20e7d7046b6b26cf9e30257ece213ebe61859024363bd0e58d7c1dcb6

# Railway-specific defaults (Railway variables still override them).
#  - PORT 3001: upstream's port; the template sets the same value.
#  - DISABLE_MDNS: no LAN discovery on Railway.
#  - NOWEN_DEPLOYMENT_TYPE: the in-app updater needs docker.sock, which Railway
#    doesn't offer; updates come from this repo instead.
#  - BACKUP_AUTO_TYPE=db-only: daily automatic backups keep 15 copies on the same
#    volume; database-only copies keep a small volume from filling up.
#  - VIPS_CONCURRENCY / UV_THREADPOOL_SIZE: Railway shows 32 host CPUs inside a
#    1 vCPU service; cap image-processing threads so 0.5 GB is enough.
ENV PORT=3001 \
    DB_PATH=/app/data/nowen-note.db \
    DISABLE_MDNS=1 \
    NOWEN_DEPLOYMENT_TYPE=railway \
    BACKUP_AUTO_TYPE=db-only \
    VIPS_CONCURRENCY=2 \
    UV_THREADPOOL_SIZE=4

COPY railway-start.sh railway-bootstrap.mjs /railway/
RUN chmod 755 /railway/railway-start.sh

# tini stays PID 1, so a crash of the app exits non-zero and Railway restarts it.
ENTRYPOINT ["/sbin/tini", "--", "/railway/railway-start.sh"]
CMD ["node", "backend/dist/index.hardened.js"]
