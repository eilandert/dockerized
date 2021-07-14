#!/bin/sh
set -e

echo "Preparing runtime...."

# =============================
# Installing template files
# =============================
if [ ! -d /repo/conf ]; then
  cp -a /tpl-repo/* /repo/

  ln -s /etc/crontab /repo/cron/
  ln -s /etc/cron.hourly /repo/cron/
  ln -s /etc/cron.daily /repo/cron/
  ln -s /etc/cron.weekly /repo/cron/
  ln -s /etc/cron.monthly /repo/cron/

  ln -s /repo/bin/repo-update-mirrors /repo/cron/cron.daily/
fi

# =============================
# Adding public folders to site
# =============================
if [ ! -L /repo/public/dists ]; then
  ln -s /repo/dists /repo/public/
fi

if [ ! -L /repo/public/pool ]; then
  ln -s /repo/pool /repo/public/
fi
# =============================

# =============================
# Fixing permissions
# =============================

# Main folder
chown -R root:root /repo

# Bin
chmod 700 /repo/bin/*

# GPG database
chmod 700 /repo/gnupg
chmod 600 /repo/gnupg/*

if [ -f /repo/gnupg/gpg.conf ]; then
  chmod 644 /repo/gnupg/gpg.conf
fi

if [ -f /repo/gnupg/tofu.db ]; then
  chmod 644 /repo/gnupg/tofu.db
fi

if [ -d /repo/gnupg/private-keys-v1.d ]; then
  chmod 700 /repo/gnupg/private-keys-v1.d
  chmod 600 /repo/gnupg/private-keys-v1.d/*
fi

if [ -f /repo/gnupg/S.gpg-agent ]; then
  chmod 1700 /repo/gnupg/S.*
fi

# SSH
chmod 600 /repo/ssh/*key
chmod 644 /repo/ssh/*.pub
chmod 600 /repo/ssh/authorized_keys

# Public site
chmod 755 /repo/public
find /repo/public -type d -exec chmod 755 {} \;
find /repo/public -type f -exec chmod 644 {} \;

# READMEs
for d in $(/bin/ls /repo); do
  if [ -f /repo/$d/README.txt ]; then
    chmod 644 /repo/$d/README.txt
  fi
done
# =============================

echo "Starting services...."
exec /usr/bin/s6-svscan /services
