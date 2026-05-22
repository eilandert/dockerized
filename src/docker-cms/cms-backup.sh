#!/bin/bash
# cms-backup — dump a WordPress (or wp-cli-compatible) site to
# /var/www/_backups/<site>/<timestamp>/. Designed to be safe to run from
# `docker exec` or a cron entry; runs as phpfpm (matches file ownership).
#
# Usage:
#   cms-backup            # backs up the site at $PWD
#   cms-backup /var/www/example.com
#   BACKUP_DIR=/srv/bak cms-backup /var/www/example.com
#
# Env:
#   BACKUP_DIR   default /var/www/_backups
#   RETAIN_DAYS  default 14  (older snapshots auto-pruned)

set -euo pipefail

SITE="${1:-$PWD}"
SITE="$(cd "$SITE" && pwd)"
NAME="$(basename "$SITE")"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
BACKUP_DIR="${BACKUP_DIR:-/var/www/_backups}"
DEST="${BACKUP_DIR}/${NAME}/${STAMP}"
RETAIN_DAYS="${RETAIN_DAYS:-14}"

[ -f "${SITE}/wp-config.php" ] || { echo "[cms-backup] $SITE does not look like a WordPress install (no wp-config.php)" >&2; exit 2; }

mkdir -p "${DEST}"
echo "[cms-backup] $(date -Iseconds) backing up $SITE → $DEST"

# DB
cd "${SITE}"
wp db export "${DEST}/db.sql" --add-drop-table --quiet
gzip -9 "${DEST}/db.sql"

# Uploads + plugins + themes (skip node_modules, vendor caches)
tar --warning=no-file-changed \
    --exclude='wp-content/cache' \
    --exclude='wp-content/uploads/cache' \
    --exclude='node_modules' \
    --exclude='vendor/bin' \
    -czf "${DEST}/files.tar.gz" \
    -C "${SITE}" wp-content

# wp-config (sanitized — strip secrets via grep)
grep -v -E "'(DB_PASSWORD|AUTH_KEY|SECURE_AUTH_KEY|LOGGED_IN_KEY|NONCE_KEY|AUTH_SALT|SECURE_AUTH_SALT|LOGGED_IN_SALT|NONCE_SALT)'" \
    "${SITE}/wp-config.php" > "${DEST}/wp-config.sanitized.php" || true

# Manifest
{
    echo "site: ${SITE}"
    echo "name: ${NAME}"
    echo "timestamp: ${STAMP}"
    echo "host: $(hostname)"
    echo "wp_version: $(wp core version --quiet 2>/dev/null || echo unknown)"
    echo "db_size: $(du -b "${DEST}/db.sql.gz" | cut -f1)"
    echo "files_size: $(du -b "${DEST}/files.tar.gz" | cut -f1)"
} > "${DEST}/MANIFEST"

# Prune old
find "${BACKUP_DIR}/${NAME}" -mindepth 1 -maxdepth 1 -type d -mtime "+${RETAIN_DAYS}" -exec rm -rf {} + 2>/dev/null || true

echo "[cms-backup] done: ${DEST}"
