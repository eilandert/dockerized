# This file might be outdated, see https://github.com/eilandert/dockerized/tree/master/roundcube for a recent one

FROM    eilandert/debian-base:stable
LABEL   maintainer="Thijs Eilander <eilander@myguard.nl>"
ENV     DEBIAN_FRONTEND="noninteractive"
ENV     INSTALLDIR="/var/www/html"
ENV	LD_PRELOAD=""
# fetch the last version, generated in the docker build script
COPY     .lastversion /tmp/lastversion
COPY	bootstrap.sh /
ENV	PHPVERSION="8.2"
ENV	COMPOSER_ALLOW_SUPERUSER=1

RUN set -x ;\
	echo "deb [trusted=yes] http://edge.deb.myguard.nl:8888/mirror/ondrej-php ${DIST} main"  > /etc/apt/sources.list.d/ondrej-ppa.list ;\
	apt-get update ;\
	apt-get -y install --no-install-recommends \
	angie-minimal \
	aspell \
	aspell-en \
	aspell-nl \ 
	dbconfig-no-thanks \
	dictionaries-common \
	enchant-2 \
	fonts-glyphicons-halflings \
	hunspell-en-us \
	libjs-bootstrap4 \
	libjs-codemirror \
	libjs-jquery-minicolors \
	libjs-jquery-ui \
	libjs-jstimezonedetect \
	libjs-popper.js \
	libjs-sizzle \
	libonig5 \
	node-jquery \
        php${PHPVERSION}-fpm \
        php${PHPVERSION}-gd \
        php${PHPVERSION}-intl \
	php${PHPVERSION}-imap \
        php${PHPVERSION}-mbstring \
        php${PHPVERSION}-mysql \
        php${PHPVERSION}-opcache \
        php${PHPVERSION}-readline \
        php${PHPVERSION}-redis \
        php${PHPVERSION}-snuffleupagus \
        php${PHPVERSION}-xml \
        php${PHPVERSION}-zip 

RUN set -ex ;\
    cd /tmp ;\
    /usr/bin/php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" ;\
    cat /tmp/composer-setup.php | /usr/bin/php -- --filename=composer --install-dir=/usr/bin ;\
    /usr/bin/php -r "unlink('composer-setup.php');" 

RUN set -x ;\
    LASTVERSION=$(cat /tmp/lastversion) ;\
    apt-get -y update ;\
    apt-get install -y --no-install-recommends \
      git \
      unzip \
      curl \
      locales ;\
    rm -rf ${INSTALLDIR} ;\
    mkdir ${INSTALLDIR} ;\
    curl -fSL https://github.com/roundcube/roundcubemail/releases/download/${LASTVERSION}/roundcubemail-${LASTVERSION}-complete.tar.gz | \
      tar xz --strip-components=1 -C ${INSTALLDIR} ;\
    cd ${INSTALLDIR} ;\
    mv composer.json-dist composer.json ;\
    composer config -g secure-http false ;\
    composer -n update --no-dev;\
#    bin/install-jsdeps.sh ;\
    composer -n require mobiledetect/mobiledetectlib ;\
    composer -n require roundcube/elastic4mobile dev-master ;\
    #2fa
    composer -n require kolab/kolab_2fa ;\
    composer require endroid/qr-code ;\
    composer require spomky-labs/otphp --no-update ;\
    composer require enygma/yubikey ;\

    #misc
#    composer require ss88/easy_unsubscribe ;\
 
    cd ${INSTALLDIR} ;\
    mkdir -p plugins/authres ;\
    curl -L https://github.com/pimlie/authres_status/archive/master.tar.gz | \
      tar xz --strip-components=1 -C plugins/authres ;\
    cd ${INSTALLDIR} ;\
    mkdir -p plugins/easy_unsubscribe ;\
    curl -L https://github.com/SS88UK/roundcube-easy-unsubscribe/archive/master.tar.gz | \
      tar xz --strip-components=1 -C plugins/easy_unsubscribe ;\
    cd ${INSTALLDIR} ;\
   #show_folder_size
   mkdir -p plugins/show_folder_size ;\
   curl -L https://github.com/jfcherng-roundcube/plugin-show-folder-size/archive/master.tar.gz | \
     tar xz --strip-components=1 -C plugins/show_folder_size ;\
   #quota
   mkdir -p plugins/quota ;\
   curl -L https://github.com/jfcherng-roundcube/plugin-quota/archive/master.tar.gz | \
     tar xz --strip-components=1 -C plugins/quota ;\
   #account_details
    mkdir -p plugins/account_details ;\
    curl -L https://github.com/texxasrulez/account_details/archive/master.tar.gz | \
      tar xz --strip-components=1 -C plugins/account_details ;\ 
   #responses
    mkdir -p plugins/responses ;\
    curl -L https://github.com/random-cuber/responses/archive/master.tar.gz | \
      tar xz --strip-components=1 -C plugins/responses ;\
    #fail2ban
    mkdir -p plugins/fail2ban ;\
    curl -L https://github.com/texxasrulez/roundcube_fail2ban/archive/master.tar.gz | \
      tar xz --strip-components=1 -C plugins/fail2ban ;\
    #RCGuard
    mkdir -p plugins/rcguard ;\
    curl -L https://github.com/dsoares/roundcube-rcguard/archive/master.tar.gz | \
      tar xz --strip-components=1 -C plugins/rcguard ;\
    #swipe
    mkdir -p plugins/swipe ;\
    curl -L https://github.com/johndoh/roundcube-swipe/archive/master.tar.gz | \
      tar xz --strip-components=1 -C plugins/swipe ;\
    #advanced_search
    mkdir -p plugins/advanced_search ;\
    curl -L https://github.com/texxasrulez/advanced_search/archive/master.tar.gz | \
      tar xz --strip-components=1 -C plugins/advanced_search ;\
    #persistent_login
    mkdir -p plugins/persistent_login ;\
    curl -L https://github.com/texxasrulez/persistent_login/archive/master.tar.gz | \
      tar xz --strip-components=1 -C plugins/persistent_login ;\
    # Context Menu
    mkdir -p plugins/contextmenu ;\
    curl -L https://github.com/johndoh/roundcube-contextmenu/archive/master.tar.gz | \
      tar xz --strip-components=1 -C plugins/contextmenu ;\
    # Context Menu Folder
    mkdir -p plugins/contextmenu_folder ;\
    curl -L https://github.com/random-cuber/contextmenu_folder/archive/master.tar.gz | \
      tar xz --strip-components=1 -C plugins/contextmenu_folder ;\
    # Message Highlight
    mkdir -p plugins/message_highlight ;\
    curl -L https://github.com/texxasrulez/message_highlight/archive/master.tar.gz | \
      tar xz --strip-components=1 -C plugins/message_highlight ;\
    #Infinite Scroll
    mkdir -p plugins/infinitescroll ;\
    curl -L https://github.com/messagerie-melanie2/Roundcube-Plugin-Infinite-Scroll/archive/master.tar.gz | \
      tar xz --strip-components=1 -C plugins/infinitescroll ;\
    # Thunderbird Labels
    mkdir -p plugins/thunderbird_labels ;\
    curl -L https://github.com/mike-kfed/rcmail-thunderbird-labels/archive/master.tar.gz | \
      tar xz --strip-components=1 -C plugins/thunderbird_labels ;\
    # Remove Attach Position
    mkdir -p plugins/attachment_position ;\
    curl -L https://github.com/filhocf/roundcube-attachment_position/archive/master.tar.gz | \
      tar xz --strip-components=1 -C plugins/attachment_position ;\
    # HTML5 Notifier
    mkdir -p plugins/html5_notifier ;\
    curl -L https://github.com/filhocf/roundcube-html5_notifier/archive/master.tar.gz | \
      tar xz --strip-components=1 -C plugins/html5_notifier ;\
 #   mkdir -p skins/mabola ;\
 #   curl -L https://github.com/EstudioNexos/mabola/archive/master.tar.gz | \
 #     tar xz --strip-components=1 -C skins/mabola ;\
    # Mabola theme
 #   mkdir -p skins/mabola-blue ;\
 #   curl -L https://github.com/EstudioNexos/mabola-blue/archive/master.tar.gz | \
 #     tar xz --strip-components=1 -C skins/mabola-blue ;\
    # Chameleon theme
 #   mkdir -p skins/chameleon ;\
 #   curl -L https://github.com/daniele-athome/roundcubemail-skin-chameleon/archive/master.tar.gz | \
 #     tar xz --strip-components=1 -C skins/chameleon ;\
    # Chameleon Blue theme
 #   mkdir -p skins/chameleon-blue ;\
 #   curl -L https://github.com/Anisotropic/Chameleon-blue/archive/master.tar.gz | \
 #     tar xz --strip-components=1 -C skins/chameleon-blue ;\
    # Classic
    mkdir -p skins/larry ;\
    curl -L https://github.com/roundcube/larry/archive/master.tar.gz | \
	tar xz --strip-components=1 -C skins/larry ;\
    mkdir -p skins/classic ;\
    curl -L https://github.com/roundcube/classic/archive/master.tar.gz | \
      tar xz --strip-components=1 -C skins/classic ;\
    for dir in `ls plugins`; do if [ -d plugins/$dir ]; then if [ -f plugins/$dir/composer.json ]; then echo $dir; composer upgrade plugins/$dir --no-dev; fi; fi; done ;\
    composer clear-cache ;\
    echo "include=/var/roundcube/config/phpfpm.conf;" >> /etc/php/${PHPVERSION}/fpm/pool.d/www.conf ;\
    echo "include /var/roundcube/config/angie.conf;" > /etc/angie/sites-available/default ;\
    mkdir -p /var/roundcube/config.orig ;\
    cp ${INSTALLDIR}/config/defaults.inc.php /var/roundcube/config.orig ;\
    touch /var/roundcube/config.orig/phpfpm.conf.override ;\
    cp -rp ${INSTALLDIR}/plugins ${INSTALLDIR}/plugins.orig ;\
    apt-get -y purge git mailutils nullmailer curl ;\
    apt-get -y autoremove && apt-get -y clean && apt-get -y autoclean ;\
    rm -rf /var/lib/apt/lists/* /tmp/* ;\
    cd ${INSTALLDIR} ;\
    rm -rf ${INSTALLDIR}/installer ${INSTALLDIR}/.ci ${INSTALLDIR}/.tx ${INSTALLDIR}/.git* ${INSTALLDIR}/.travis.yml /root/.c* ;\
    rm -rf README.md INSTALL UPGRADING, LICENSE, CHANGELOG tests ${INSTALLDIR}/plugins/*/.git* ;\
    rm -f ${INSTALLDIR}/index.html ;\
    chown -R www-data:www-data ${INSTALLDIR}/logs ;\
    chown -R www-data:www-data ${INSTALLDIR}/temp ;\
    chmod +x /bootstrap.sh ;\
    mv /etc/php /etc/php.orig ;\
    mv /etc/angie /etc/angie.orig

COPY angie.conf /var/roundcube/config.orig
COPY phpfpm.conf /var/roundcube/config.orig

WORKDIR ${INSTALLDIR}
ENTRYPOINT ["/bootstrap.sh"]
