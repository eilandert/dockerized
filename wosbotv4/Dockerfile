FROM    python:slim-bookworm
LABEL   maintainer="Thijs Eilander <eilander@myguard.nl>"

COPY    bootstrap.sh /bootstrap.sh
COPY app /app
RUN set -x; \
        apt update ;\
	apt-get install --no-install-recommends -y git ;\
	pip install --upgrade pip ;\
	cd / ;\
#	/usr/bin/git clone https://github.com/eilandert/wosbot.git app ;\
	cd /app ;\
	git checkout main ;\
	echo 0 > bot_token.txt ;\
        pip install numpy Pillow opencv-python-headless onnxruntime --no-cache-dir;\
        pip install ddddocr==1.5.6 --no-cache-dir --force-reinstall --ignore-requires-python --break-system-packages ;\
	pip install --no-cache-dir certifi requests colorama discord aiohttp-socks pytz pyzipper ;\
	python main.py --autoupdate ;\
	rm bot_token.txt ;\
	chmod +x /bootstrap.sh ;\
	apt-get -y autoremove && apt-get -y autoclean && rm -rf /var/lib/apt/lists/*

WORKDIR /app
ENTRYPOINT ["/bootstrap.sh"]

