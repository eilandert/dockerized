group "default" {
    targets = [
	"rolling",
	"devel",
	"bookworm",
	]
}

group "base-current" {
    targets = ["jammy", "bookworm"]
}

group "base" {
    targets = ["rolling", "devel","jammy","focal","bionic","bookworm","bullseye","buster"]
}

group "phpfpm" {
    targets = [
        "ubuntu-phpfpm56",
 #       "debian-phpfpm56",
        "ubuntu-phpfpm72",
        "debian-phpfpm72",
        "ubuntu-phpfpm74",
        "debian-phpfpm74",
        "ubuntu-phpfpm80",
        "debian-phpfpm80",
        "ubuntu-phpfpm81",
        "debian-phpfpm81",
        "ubuntu-phpfpm82",
        "debian-phpfpm82",
        "ubuntu-phpfpm83",
        "debian-phpfpm83",
    ]
}

group "multiphp" {
    targets = [
        "ubuntu-multiphp",
        "debian-multiphp",
    ]
}

group "nginx" {
    targets = [
       "debian-nginx",
       "ubuntu-nginx",
       "alpine-nginx",
    ]
}

group "nginx-quic" {
    targets = [
       "debian-nginx-quic",
       "ubuntu-nginx-quic",
    ]
}

group "nginx-php" {
    targets = [
       "ubuntu-nginx-php56",
       "debian-nginx-php56",
       "ubuntu-nginx-php72",
       "debian-nginx-php72",
       "ubuntu-nginx-php74",
       "debian-nginx-php74",
       "ubuntu-nginx-php80",
       "debian-nginx-php80",
       "ubuntu-nginx-php81",
       "debian-nginx-php81",
       "ubuntu-nginx-php82",
       "debian-nginx-php82",
       "ubuntu-nginx-php83",
       "debian-nginx-php83",
       "ubuntu-nginx-multi",
       "debian-nginx-multi",
    ]
}

group "apache" {
    targets = [
       "debian-apache-php56",
       "debian-apache-php72",
       "debian-apache-php74",
       "debian-apache-php80",
       "debian-apache-php81",
       "debian-apache-php82",
       "debian-apache-php83",
       "debian-apache-multiphp",
       "ubuntu-apache-php56",
       "ubuntu-apache-php72",
       "ubuntu-apache-php74",
       "ubuntu-apache-php80",
       "ubuntu-apache-php81",
       "ubuntu-apache-php82",
       "ubuntu-apache-php83",
       "ubuntu-apache-multiphp",
    ]
}

group "apache-misc" {
    targets = [
       "ubuntu-roundcube",
       "debian-roundcube",
#       "alpine-vimbadmin",
       "debian-vimbadmin",
       "ubuntu-vimbadmin",
    ]
}

group "mail" {
    targets = [
       "ubuntu-postfix",
       "debian-postfix",
       "alpine-rspamd",
       "debian-rspamd-git",
       "debian-rspamd",
       "debian-rspamd-official",
       "ubuntu-rspamd",
       "ubuntu-dovecot",
       "debian-dovecot",
    ]
}

group "db" {
    targets = [
        "alpine-redis",
        "ubuntu-redis",
        "debian-redis",
	"ubuntu-mariadb",
	"debian-mariadb",
    ]
}

group "misc" {
    targets = [
 #      "clamav",
       "alpine-letsencrypt",
       "rbldnsd",
       "ubuntu-reprepro",
       "debian-sitewarmup",
       "alpine:unbound",
       "aptly",
        "debian-openssh",
    ]
}

target "rolling" {
    dockerfile = "Dockerfile-rolling"
    context = "base"
    tags = ["docker.io/eilandert/ubuntu-base:rolling"]
}

target "devel" {
    dockerfile = "Dockerfile-devel"
    context = "base"
    tags = ["docker.io/eilandert/ubuntu-base:devel"]
}

target "jammy" {
    dockerfile = "Dockerfile-jammy"
    context = "base"
    tags = ["docker.io/eilandert/ubuntu-base:jammy"]
}

target "focal" {
    dockerfile = "Dockerfile-focal"
    context = "base"
    tags = ["docker.io/eilandert/ubuntu-base:focal"]
}

target "bionic" {
    dockerfile = "Dockerfile-bionic"
    context = "base"
    tags = ["docker.io/eilandert/ubuntu-base:bionic"]
}

target "xenial" {
    dockerfile = "Dockerfile-xenial"
    context = "base"
    tags = ["docker.io/eilandert/ubuntu-base:xenial"]
}

target "trusty" {
    dockerfile = "Dockerfile-trusty"
    context = "base"
    tags = ["docker.io/eilandert/ubuntu-base:trusty"]
}

target "bookworm" {
    dockerfile = "Dockerfile-bookworm"
    context = "base"
    tags = ["docker.io/eilandert/debian-base:bookworm","docker.io/eilandert/debian-base:stable"]
}

target "bullseye" {
    dockerfile = "Dockerfile-bullseye"
    context = "base"
    tags = ["docker.io/eilandert/debian-base:bullseye"]
}

target "buster" {
    dockerfile = "Dockerfile-buster"
    context = "base"
    tags = ["docker.io/eilandert/debian-base:buster"]
}

target "stretch" {
    dockerfile = "Dockerfile-stretch"
    context = "base"
    tags = ["docker.io/eilandert/debian-base:stretch"]
}

target "ubuntu-phpfpm56" {
    tags = ["docker.io/eilandert/php-fpm:5.6"]
    context = "php-fpm"
    dockerfile = "Dockerfile-5.6"
    inherits = ["rolling"]
}

target "debian-phpfpm56" {
    tags = ["docker.io/eilandert/php-fpm:deb-5.6"]
    context = "php-fpm"
    dockerfile = "Dockerfile-5.6debian"
}

target "ubuntu-phpfpm72" {
    tags = ["docker.io/eilandert/php-fpm:7.2"]
    context = "php-fpm"
    dockerfile = "Dockerfile-7.2"
}
target "debian-phpfpm72" {
    tags = ["docker.io/eilandert/php-fpm:deb-7.2"]
    context = "php-fpm"
    dockerfile = "Dockerfile-7.2debian"
}

target "ubuntu-phpfpm74" {
    tags = ["docker.io/eilandert/php-fpm:7.4"]
    context = "php-fpm"
    dockerfile = "Dockerfile-7.4"
}

target "debian-phpfpm74" {
    tags = ["docker.io/eilandert/php-fpm:deb-7.4"]
    context = "php-fpm"
    dockerfile = "Dockerfile-7.4debian"
}

target "ubuntu-phpfpm80" {
    tags = ["docker.io/eilandert/php-fpm:8.0","docker.io/eilandert/php-fpm:latest"]
    context = "php-fpm"
    dockerfile = "Dockerfile-8.0"
}

target "debian-phpfpm80" {
    tags = ["docker.io/eilandert/php-fpm:deb-8.0","docker.io/eilandert/php-fpm:deb-latest"]
    context = "php-fpm"
    dockerfile = "Dockerfile-8.0debian"
}

target "ubuntu-phpfpm81" {
    tags = ["docker.io/eilandert/php-fpm:8.1"]
    context = "php-fpm"
    dockerfile = "Dockerfile-8.1"
}

target "debian-phpfpm81" {
    tags = ["docker.io/eilandert/php-fpm:deb-8.1"]
    context = "php-fpm"
    dockerfile = "Dockerfile-8.1debian"
}

target "ubuntu-phpfpm82" {
    tags = ["docker.io/eilandert/php-fpm:8.2"]
    context = "php-fpm"
    dockerfile = "Dockerfile-8.2"
}

target "debian-phpfpm82" {
    tags = ["docker.io/eilandert/php-fpm:deb-8.2"]
    context = "php-fpm"
    dockerfile = "Dockerfile-8.2debian"
}

target "ubuntu-phpfpm83" {
    tags = ["docker.io/eilandert/php-fpm:8.3"]
    context = "php-fpm"
    dockerfile = "Dockerfile-8.3"
}

target "debian-phpfpm83" {
    tags = ["docker.io/eilandert/php-fpm:deb-8.3"]
    context = "php-fpm"
    dockerfile = "Dockerfile-8.3debian"
}

target "ubuntu-multiphp" {
    tags = ["docker.io/eilandert/php-fpm:multi"]
    context = "php-fpm"
    dockerfile = "Dockerfile-multi"
}

target "debian-multiphp" {
    tags = ["docker.io/eilandert/php-fpm:deb-multi"]
    context = "php-fpm"
    dockerfile = "Dockerfile-multidebian"
}

target "debian-mariadb" {
    tags = ["docker.io/eilandert/mariadb:debian","docker.io/eilandert/mariadb:latest"]
    context = "mariadb"
    dockerfile = "Dockerfile.debian"
}

target "ubuntu-mariadb" {
    tags = ["docker.io/eilandert/mariadb:ubuntu"]
    context = "mariadb"
    dockerfile = "Dockerfile.ubuntu"
}

target "debian-nginx" {
    tags = ["docker.io/eilandert/nginx-modsecurity3-pagespeed:deb-latest"]
    context = "nginx-proxy-modsecurity-pagespeed"
    dockerfile = "Dockerfile-debian"
}

target "ubuntu-nginx" {
    tags = ["docker.io/eilandert/nginx-modsecurity3-pagespeed:latest"]
    context = "nginx-proxy-modsecurity-pagespeed"
    dockerfile = "Dockerfile"
}

target "ubuntu-nginx-php56" {
    tags = ["docker.io/eilandert/nginx-modsecurity3-pagespeed:php5.6"]
    context = "nginx-proxy-modsecurity-pagespeed"
    dockerfile = "Dockerfile-php56"
}

target "debian-nginx-php56" {
    tags = ["docker.io/eilandert/nginx-modsecurity3-pagespeed:deb-php5.6"]
    context = "nginx-proxy-modsecurity-pagespeed"
    dockerfile = "Dockerfile-php56debian"
}

target "ubuntu-nginx-php72" {
    tags = ["docker.io/eilandert/nginx-modsecurity3-pagespeed:php7.2"]
    context = "nginx-proxy-modsecurity-pagespeed"
    dockerfile = "Dockerfile-php72"
}

target "debian-nginx-php72" {
    tags = ["docker.io/eilandert/nginx-modsecurity3-pagespeed:deb-php7.2"]
    context = "nginx-proxy-modsecurity-pagespeed"
    dockerfile = "Dockerfile-php72debian"
}

target "ubuntu-nginx-php74" {
    tags = ["docker.io/eilandert/nginx-modsecurity3-pagespeed:php7.4"]
    context = "nginx-proxy-modsecurity-pagespeed"
    dockerfile = "Dockerfile-php74"
}

target "debian-nginx-php74" {
    tags = ["docker.io/eilandert/nginx-modsecurity3-pagespeed:deb-php7.4"]
    context = "nginx-proxy-modsecurity-pagespeed"
    dockerfile = "Dockerfile-php74debian"
}

target "ubuntu-nginx-php80" {
    tags = ["docker.io/eilandert/nginx-modsecurity3-pagespeed:php8.0"]
    context = "nginx-proxy-modsecurity-pagespeed"
    dockerfile = "Dockerfile-php80"
}

target "debian-nginx-php80" {
    tags = ["docker.io/eilandert/nginx-modsecurity3-pagespeed:deb-php8.0"]
    context = "nginx-proxy-modsecurity-pagespeed"
    dockerfile = "Dockerfile-php80debian"
}

target "ubuntu-nginx-php81" {
    tags = ["docker.io/eilandert/nginx-modsecurity3-pagespeed:php8.1"]
    context = "nginx-proxy-modsecurity-pagespeed"
    dockerfile = "Dockerfile-php81"
}

target "ubuntu-nginx-php82" {
    tags = ["docker.io/eilandert/nginx-modsecurity3-pagespeed:php8.2"]
    context = "nginx-proxy-modsecurity-pagespeed"
    dockerfile = "Dockerfile-php82"
}

target "ubuntu-nginx-php83" {
    tags = ["docker.io/eilandert/nginx-modsecurity3-pagespeed:php8.3"]
    context = "nginx-proxy-modsecurity-pagespeed"
    dockerfile = "Dockerfile-php83"
}

target "debian-nginx-php81" {
    tags = ["docker.io/eilandert/nginx-modsecurity3-pagespeed:deb-php8.1"]
    context = "nginx-proxy-modsecurity-pagespeed"
    dockerfile = "Dockerfile-php81debian"
}

target "debian-nginx-php82" {
    tags = ["docker.io/eilandert/nginx-modsecurity3-pagespeed:deb-php8.2"]
    context = "nginx-proxy-modsecurity-pagespeed"
    dockerfile = "Dockerfile-php82debian"
}

target "debian-nginx-php83" {
    tags = ["docker.io/eilandert/nginx-modsecurity3-pagespeed:deb-php8.3"]
    context = "nginx-proxy-modsecurity-pagespeed"
    dockerfile = "Dockerfile-php83debian"
}

target "ubuntu-nginx-multi" {
    tags = ["docker.io/eilandert/nginx-modsecurity3-pagespeed:multi"]
    context = "nginx-proxy-modsecurity-pagespeed"
    dockerfile = "Dockerfile-multi"
}

target "debian-nginx-multi" {
    tags = ["docker.io/eilandert/nginx-modsecurity3-pagespeed:deb-multi"]
    context = "nginx-proxy-modsecurity-pagespeed"
    dockerfile= "Dockerfile-multidebian"
}

target "debian-apache-php56" {
    tags = ["docker.io/eilandert/apache-phpfpm:deb-5.6"]
    context = "apache-phpfpm"
    dockerfile= "Dockerfile-5.6debian"
}

target "debian-apache-php72" {
    tags = ["docker.io/eilandert/apache-phpfpm:deb-7.2"]
    context = "apache-phpfpm"
    dockerfile= "Dockerfile-7.2debian"
}

target "debian-apache-php74" {
    tags = ["docker.io/eilandert/apache-phpfpm:deb-7.4"]
    context = "apache-phpfpm"
    dockerfile= "Dockerfile-7.4debian"
}

target "debian-apache-php80" {
    tags = ["docker.io/eilandert/apache-phpfpm:deb-8.0","docker.io/eilandert/apache-phpfpm:deb-latest"]
    context = "apache-phpfpm"
    dockerfile= "Dockerfile-8.0debian"
}

target "debian-apache-php81" {
    tags = ["docker.io/eilandert/apache-phpfpm:deb-8.1"]
    context = "apache-phpfpm"
    dockerfile= "Dockerfile-8.1debian"
}

target "debian-apache-php82" {
    tags = ["docker.io/eilandert/apache-phpfpm:deb-8.2"]
    context = "apache-phpfpm"
    dockerfile= "Dockerfile-8.2debian"
}


target "debian-apache-php83" {
    tags = ["docker.io/eilandert/apache-phpfpm:deb-8.3"]
    context = "apache-phpfpm"
    dockerfile= "Dockerfile-8.3debian"
}

target "debian-apache-multiphp" {
    tags = ["docker.io/eilandert/apache-phpfpm:deb-multi"]
    context = "apache-phpfpm"
    dockerfile= "Dockerfile-multidebian"
}

target "ubuntu-apache-php56" {
    tags = ["docker.io/eilandert/apache-phpfpm:5.6"]
    context = "apache-phpfpm"
    dockerfile= "Dockerfile-5.6"
}

target "ubuntu-apache-php72" {
    tags = ["docker.io/eilandert/apache-phpfpm:7.2"]
    context = "apache-phpfpm"
    dockerfile= "Dockerfile-7.2"
}

target "ubuntu-apache-php74" {
    tags = ["docker.io/eilandert/apache-phpfpm:7.4"]
    context = "apache-phpfpm"
    dockerfile= "Dockerfile-7.4"
}

target "ubuntu-apache-php80" {
    tags = ["docker.io/eilandert/apache-phpfpm:8.0","docker.io/eilandert/apache-phpfpm:latest"]
    context = "apache-phpfpm"
    dockerfile= "Dockerfile-8.0"
}

target "ubuntu-apache-php81" {
    tags = ["docker.io/eilandert/apache-phpfpm:8.1"]
    context = "apache-phpfpm"
    dockerfile= "Dockerfile-8.1"
}

target "ubuntu-apache-php82" {
    tags = ["docker.io/eilandert/apache-phpfpm:8.2"]
    context = "apache-phpfpm"
    dockerfile= "Dockerfile-8.2"
}

target "ubuntu-apache-php83" {
    tags = ["docker.io/eilandert/apache-phpfpm:8.3"]
    context = "apache-phpfpm"
    dockerfile= "Dockerfile-8.3"
}


target "ubuntu-apache-multiphp" {
    tags = ["docker.io/eilandert/apache-phpfpm:multi"]
    context = "apache-phpfpm"
    dockerfile= "Dockerfile-multi"
}

target "clamav" {
   tags = ["docker.io/eilandert/clamav-unofficial-sigs"]
   context = "clamav-unofficial-signatures"
   dockerfile = "Dockerfile" 
}

target "ubuntu-dovecot" {
   tags = ["docker.io/eilandert/dovecot:ubuntu","docker.io/eilandert/dovecot:latest"]
   context = "dovecot-ubuntu"
   dockerfile = "Dockerfile"
}

target "debian-dovecot" {
   tags = ["docker.io/eilandert/dovecot:debian"]
   context = "dovecot-ubuntu"
   dockerfile = "Dockerfile-debian"
}

target "alpine-letsencrypt" {
   tags = ["docker.io/eilandert/letsencrypt"]
   context = "letsencrypt"
   dockerfile = "Dockerfile"
}

target "alpine-nginx" {
   tags = ["docker.io/eilandert/nginx-alpine"]
   context = "nginx-alpine"
   dockerfile = "Dockerfile"
}

target "ubuntu-postfix" {
   tags = ["docker.io/eilandert/postfix:ubuntu","docker.io/eilandert/postfix:latest"]
   context = "postfix"
   dockerfile = "Dockerfile"
}

target "debian-postfix" {
   tags = ["docker.io/eilandert/postfix:debian"]
   context = "postfix"
   dockerfile = "Dockerfile-debian"
}

target "rbldnsd" {
   tags = ["docker.io/eilandert/rbldnsd"]
   context = "rbldnsd"
   dockerfile = "Dockerfile"
}

target "alpine-redis" {
   tags = ["docker.io/eilandert/redis:scratch"]
   context = "redis6-scratch"
   dockerfile = "Dockerfile"
}

target "ubuntu-redis" {
   tags = ["docker.io/eilandert/redis:ubuntu"]
   context = "redis"
   dockerfile = "Dockerfile.ubuntu"
}

target "debian-redis" {
   tags = ["docker.io/eilandert/redis:debian"]
   context = "redis"
   dockerfile = "Dockerfile.debian"
}

target "ubuntu-reprepro" {
   tags = ["docker.io/eilandert/reprepro"]
   context = "reprepro"
   dockerfile = "Dockerfile"
}

target "ubuntu-roundcube" {
   tags = ["docker.io/eilandert/roundcube:ubuntu","docker.io/eilandert/roundcube:latest"]
   context = "roundcube"
   dockerfile = "Dockerfile-ubuntu"
}

target "debian-roundcube" {
   tags = ["docker.io/eilandert/roundcube:debian"]
   context = "roundcube"
   dockerfile = "Dockerfile-debian"
}

target "alpine-rspamd" {
   tags = ["docker.io/eilandert/rspamd"]
   context = "rspamd"
   dockerfile = "Dockerfile"
}

target "debian-rspamd-git" {
   tags = ["docker.io/eilandert/rspamd-git:latest"]
   context = "rspamd-git"
   dockerfile = "Dockerfile"
}
target "debian-rspamd-official" {
   tags = ["docker.io/eilandert/rspamd-git:official"]
   context = "rspamd-git"
   dockerfile = "Dockerfile-official"
}

target "debian-rspamd" {
   tags = ["docker.io/eilandert/rspamd-git:debian","docker.io/eilandert/rspamd-git:release"]
   context = "rspamd-git"
   dockerfile = "Dockerfile-debian"
}
target "ubuntu-rspamd" {
   tags = ["docker.io/eilandert/rspamd-git:ubuntu"]
   context = "rspamd-git"
   dockerfile = "Dockerfile-stable"
}
target "debian-sitewarmup" {
   tags = ["docker.io/eilandert/sitemap_warmup"]
   context = "sitemap_warmup"
   dockerfile = "Dockerfile"
}
target "alpine:unbound" {
   tags = ["docker.io/eilandert/unbound"]
   context = "unbound"
   dockerfile = "Dockerfile"
}
target "alpine-vimbadmin" {
   tags = ["docker.io/eilandert/vimbadmin:alpine"]
   context = "vimbadmin"
   dockerfile = "Dockerfile"
}
target "debian-vimbadmin" {
   tags = ["docker.io/eilandert/vimbadmin:debian","docker.io/eilandert/vimbadmin:latest"]
   context = "vimbadmin-ubuntu"
   dockerfile = "Dockerfile-debian"
}
target "ubuntu-vimbadmin" {
   tags = ["docker.io/eilandert/vimbadmin:ubuntu"]
   context = "vimbadmin-ubuntu"
   dockerfile = "Dockerfile"
}
target "psol" {
   tags = ["docker.io/eilandert/psol"]
   context = "psol-build"
   dockerfile = "Dockerfile"
}

target "debian-openssh" {
   tags = ["docker.io/eilandert/openssh:debian"]
   context = "openssh"
   dockerfile = "Dockerfile-debian"
}

target "aptly" {
   tags = ["docker.io/eilandert/aptly"]
   context = "aptly"
   dockerfile = "Dockerfile"
}

target "debian-nginx-quic" {
    tags = ["docker.io/eilandert/nginx-quic:deb-latest"]
    context = "nginx-quic"
    dockerfile = "Dockerfile-debian"
}

target "ubuntu-nginx-quic" {
    tags = ["docker.io/eilandert/nginx-quic:latest"]
    context = "nginx-quic"
    dockerfile = "Dockerfile"
}

target "ubuntu-nginx-quic-php56" {
    tags = ["docker.io/eilandert/nginx-quic:php5.6"]
    context = "nginx-quic"
    dockerfile = "Dockerfile-php56"
}

target "debian-nginx-quic-php56" {
    tags = ["docker.io/eilandert/nginx-quic:deb-php5.6"]
    context = "nginx-quic"
    dockerfile = "Dockerfile-php56debian"
}

target "ubuntu-nginx-quic-php72" {
    tags = ["docker.io/eilandert/nginx-quic:php7.2"]
    context = "nginx-quic"
    dockerfile = "Dockerfile-php72"
}

target "debian-nginx-quic-php72" {
    tags = ["docker.io/eilandert/nginx-quic:deb-php7.2"]
    context = "nginx-quic"
    dockerfile = "Dockerfile-php72debian"
}

target "ubuntu-nginx-quic-php74" {
    tags = ["docker.io/eilandert/nginx-quic:php7.4"]
    context = "nginx-quic"
    dockerfile = "Dockerfile-php74"
}

target "debian-nginx-quic-php74" {
    tags = ["docker.io/eilandert/nginx-quic:deb-php7.4"]
    context = "nginx-quic"
    dockerfile = "Dockerfile-php74debian"
}

target "ubuntu-nginx-quic-php80" {
    tags = ["docker.io/eilandert/nginx-quic:php8.0"]
    context = "nginx-quic"
    dockerfile = "Dockerfile-php80"
}

target "debian-nginx-quic-php80" {
    tags = ["docker.io/eilandert/nginx-quic:deb-php8.0"]
    context = "nginx-quic"
    dockerfile = "Dockerfile-php80debian"
}

target "ubuntu-nginx-quic-php81" {
    tags = ["docker.io/eilandert/nginx-quic:php8.1"]
    context = "nginx-quic"
    dockerfile = "Dockerfile-php81"
}

target "ubuntu-nginx-quic-php82" {
    tags = ["docker.io/eilandert/nginx-quic:php8.2"]
    context = "nginx-quic"
    dockerfile = "Dockerfile-php82"
}

target "debian-nginx-quic-php81" {
    tags = ["docker.io/eilandert/nginx-quic:deb-php8.1"]
    context = "nginx-quic"
    dockerfile = "Dockerfile-php81debian"
}

target "debian-nginx-quic-php82" {
    tags = ["docker.io/eilandert/nginx-quic:deb-php8.2"]
    context = "nginx-quic"
    dockerfile= "Dockerfile-php82debian"
}


target "ubuntu-nginx-quic-multi" {
    tags = ["docker.io/eilandert/nginx-quic:multi"]
    context = "nginx-quic"
    dockerfile = "Dockerfile-multi"
}

target "debian-nginx-quic-multi" {
    tags = ["docker.io/eilandert/nginx-quic:deb-multi"]
    context = "nginx-quic"
    dockerfile= "Dockerfile-multidebian"
}


# on request... no bookworm but bullseye. remove after 1-1-2025
target "debian-phpfpm81bullseye" {
    tags = ["docker.io/eilandert/php-fpm:8.1bullseye"]
    context = "php-fpm"
    dockerfile = "Dockerfile-8.1bullseye"
}
# same
target "debian-apache-php81bullseye" {
    tags = ["docker.io/eilandert/apache-phpfpm:8.1bullseye"]
    context = "apache-phpfpm"
    dockerfile= "Dockerfile-8.1bullseye"
}

