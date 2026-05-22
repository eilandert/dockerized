#!/bin/sh
# CMS bootstrap — starts cron in the background and then chains into the
# angie bootstrap inherited from the base image (saved at /bootstrap-angie.sh
# by the Dockerfile). The angie bootstrap takes care of timezone, nullmailer,
# PHP-FPM startup, and finally execs angie in foreground.
set -e

# Generate a runtime ~/.my.cnf for the admin shell if DB_HOST/DB_USER/DB_PASS
# are set in the env. Lets `mysql` / `mariadb-dump` just work in `docker exec`.
if [ -n "${DB_HOST:-}" ] && [ -n "${DB_USER:-}" ] && [ -n "${DB_PASS:-}" ]; then
    {
        echo '[client]'
        echo "host=${DB_HOST}"
        echo "user=${DB_USER}"
        echo "password=${DB_PASS}"
        [ -n "${DB_NAME:-}" ] && echo "database=${DB_NAME}"
    } > /root/.my.cnf
    chmod 0600 /root/.my.cnf
fi

# Cron — only start if there is at least one /etc/cron.d entry.
if [ -d /etc/cron.d ] && [ -n "$(ls -A /etc/cron.d 2>/dev/null)" ]; then
    /usr/sbin/cron
    echo "[CMS] cron daemon started"
fi

echo "[CMS] handing off to angie bootstrap"
exec /bootstrap.sh
