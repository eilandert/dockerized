FROM    eilandert/ubuntu-base:rolling
LABEL   maintainer="Thijs Eilander <eilander@myguard.nl>"
ENV     DEBIAN_FRONTEND="noninteractive"
ENV     LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2

COPY    bootstrap.sh /bootstrap.sh

COPY user.conf /config.orig/clamav-unofficial-sigs/user.conf
COPY bootstrap.sh /bootstrap.sh
COPY check.sh /check.sh

RUN set -ex ;\
  apt-get update ;\
  apt-get -y --no-install-recommends install bash wget curl curl rsync tzdata bind9-host bind9-dnsutils ;\  
  apt-get -y --no-install-recommends install clamav clamav-daemon clamav-freshclam libclamunrar clamav-milter clamdscan ;\ 
  mkdir -p /usr/local/sbin/ ;\
  mkdir -p /config.orig/clamav-unofficial-sigs ;\
  mv /etc/clamav /config.orig ;\
  curl -s https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/clamav-unofficial-sigs.sh -o /usr/local/sbin/clamav-unofficial-sigs.sh ;\
  curl -s https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/master.conf -o /config.orig/clamav-unofficial-sigs/master.conf ;\
  curl -s https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/os/os.ubuntu.conf -o /config.orig/clamav-unofficial-sigs/os.conf ;\
  chmod +x /usr/local/sbin/clamav-unofficial-sigs.sh ;\
  chmod +x /bootstrap.sh ;\
  chmod +x /check.sh ;\
  apt-get -y autoremove && apt-get -y autoclean && rm -rf /var/lib/apt/lists/* ;\
  sed -i /Proxy/d /config.orig/clamav/freshclam.conf ;\
  sed -i /^#/d /config.orig/clamav/*.conf ;\
  sed -i s/work_dir_urlhaust/work_dir_urlhaus/ /usr/local/sbin/clamav-unofficial-sigs.sh ;\  
  echo "background_thread:true,metadata_thp:auto" > /etc/malloc.conf

CMD ["/bootstrap.sh"]
EXPOSE 3310/tcp
VOLUME ["/var/lib/clamav"]
HEALTHCHECK CMD /check.sh
