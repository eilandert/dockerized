FROM    eilandert/debian-base:stable
LABEL   maintainer="Thijs Eilander <eilander@myguard.nl>"

COPY main.py /root/warmup_sitemaps/main.py
COPY requirements.txt /root/warmup_sitemaps/requirements.txt

RUN	apt-get -y update \
	&& apt-get --no-install-recommends install -y python3-pip \
	&& pip3 install --break-system-packages --upgrade -r /root/warmup_sitemaps/requirements.txt \
	&& chmod 755 /root/warmup_sitemaps/main.py \
        && apt-get -y autoremove \
	&& apt-get -y autoclean \
	&& rm -rf /var/lib/apt/lists/* \
	&& rm -rf /root/.cache

ENTRYPOINT ["/root/warmup_sitemaps/main.py"]
