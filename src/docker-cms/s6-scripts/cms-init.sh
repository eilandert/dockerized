#!/bin/sh
# s6 oneshot for the CMS image: runtime ~/.my.cnf for the admin shell so
# `mysql`/`mariadb-dump` work in `docker exec` when DB_* env is set. (Cron is a
# separate longrun.) Replaces the old bootstrap-cms.sh wrapper, which is gone now
# that the base image is s6-supervised (no more `exec /bootstrap.sh`).
exec 2>&1
if [ -n "${DB_HOST:-}" ] && [ -n "${DB_USER:-}" ] && [ -n "${DB_PASS:-}" ]; then
    {
        echo '[client]'
        echo "host=${DB_HOST}"
        echo "user=${DB_USER}"
        echo "password=${DB_PASS}"
        [ -n "${DB_NAME:-}" ] && echo "database=${DB_NAME}"
    } > /root/.my.cnf
    chmod 0600 /root/.my.cnf
    echo "[CMS] wrote /root/.my.cnf from DB_* env"
fi
exit 0
