FROM    ubuntu:latest
LABEL   maintainer="Thijs Eilander <eilander@myguard.nl>"
ENV     DEBIAN_FRONTEND="noninteractive"

COPY    bootstrap.sh /bootstrap.sh

RUN     apt-get -y update && apt -y upgrade \
        && apt-get install -y --no-install-recommends ca-certificates apt-utils \
        && dpkg-statoverride --update --add root adm 0000 /usr/bin/sudo \
        && dpkg-statoverride --update --add root adm 0000 /bin/su \
	&& dpkg-statoverride --update --add root adm 0500 /usr/bin/ping \
	&& chmod +x /bootstrap.sh

RUN     sh -x \
        && for user in `awk -F: '($3 < 1000) {print $1 }' /etc/passwd`; do \
          if [ $user != "root" ]; then \
            usermod -L $user && usermod -s /usr/sbin/nologin $user ;\
          fi ;\
        done

CMD     ["/bootstrap.sh"]

