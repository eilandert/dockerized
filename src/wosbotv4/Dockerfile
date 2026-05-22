# syntax=docker/dockerfile:1.7
FROM    python:slim-bookworm
LABEL   org.opencontainers.image.authors="eilandert" \
        org.opencontainers.image.source="https://github.com/eilandert/dockerized" \
        maintainer="Thijs Eilander <eilander@myguard.nl>"
ENV     DEBIAN_FRONTEND="noninteractive" \
        PIP_NO_CACHE_DIR=1 \
        PIP_DISABLE_PIP_VERSION_CHECK=1

COPY --chmod=0755 bootstrap.sh /bootstrap.sh
COPY app /app

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    set -xe ;\
    rm -f /etc/apt/apt.conf.d/docker-clean ;\
    apt-get update ;\
    apt-get install --no-install-recommends -y git ;\
    apt-get -y autoremove

RUN --mount=type=cache,target=/root/.cache/pip,sharing=locked \
    set -xe ;\
    pip install --upgrade pip ;\
    cd /app ;\
    git checkout main ;\
    echo 0 > bot_token.txt ;\
    pip install numpy Pillow opencv-python-headless onnxruntime ;\
    pip install ddddocr==1.5.6 --force-reinstall --ignore-requires-python --break-system-packages ;\
    pip install certifi requests colorama discord aiohttp-socks pytz pyzipper ;\
    python main.py --autoupdate ;\
    rm -f bot_token.txt

WORKDIR /app

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 CMD test -f /tmp/healthy && find /tmp/healthy -mmin -10 | grep -q . || exit 1

ENTRYPOINT ["/bootstrap.sh"]
