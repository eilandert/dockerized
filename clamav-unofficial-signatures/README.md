ClamAV with Unofficial Signatures Updater.
Dockerized ClamAV based on eilandert/ubuntu-base:rolling with clamav-unofficial-sigs

bootstrap.sh will (re)populate the configuration dirs if clamd.conf is missing and runs the freshclam and unofficial-sigs updaters when needed.

The docker-compose.yml is on my github, otherwise bind /config to get to the configs.

Daily rebuild for latest ubuntu and packages.

That's it, have fun.
