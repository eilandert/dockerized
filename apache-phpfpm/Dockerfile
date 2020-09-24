FROM    ubuntu:latest
ENV DEBIAN_FRONTEND="noninteractive"

COPY    bootstrap.sh /bootstrap.sh

RUN     apt-get -y update && apt -y upgrade \
        && apt-get install -y --no-install-recommends ca-certificates software-properties-common \
        && add-apt-repository -y ppa:ondrej/apache2 && add-apt-repository -y ppa:ondrej/php \
        && apt-get -y update && apt-get -y upgrade \
        && apt install -y --no-install-recommends apache2 php7.4 php7.4-igbinary php-imagick php7.4-redis php7.4-mysql \
                php7.4-bcmath php7.4-cli php7.4-curl php7.4-dom php7.4-fpm php7.4-gd php7.4-json php7.4-mbstring php7.4-mysql php7.4-opcache \
                php7.4-readline php7.4-soap php7.4-xml php7.4-zip php7.4-tidy php-apcu \
        && apt install -y nullmailer mailutils preload \
        && apt-get -y purge software-properties-common unattended-upgrades \
        && apt-get -y autoremove && apt-get -y autoclean && rm -rf /var/lib/apt/lists/* \
        && dpkg-statoverride --update --add root adm 0000 /bin/su \
        && rm -rf /etc/php/5.6 /etc/php/7.0 /etc/php/7.1 /etc/php/7.2 /etc/php/7.3 \
        && mv /etc/apache2 /etc/apache2.orig && mkdir -p /etc/apache2 \
        && mv /etc/php /etc/php.orig && mkdir -p /etc/php \
        && mv /etc/nullmailer /etc/nullmailer.orig && mkdir -p /etc/nullmailer \
        && chmod +x /bootstrap.sh 

CMD     ["/bootstrap.sh"]
EXPOSE  80 80
EXPOSE  443 443

