group "default" {
    targets = [
    "rolling", "devel" ]
}

group "base-current" {
    targets = ["resolute", "noble", "trixie", "rolling"]
}

group "base" {
    targets = ["rolling", "devel", "resolute", "noble", "jammy", "focal", "bionic", "trixie", "bookworm", "bullseye", "buster"]
}

group "phpfpm" {
    targets = [
       "ubuntu-phpfpm56", "debian-phpfpm56", "ubuntu-phpfpm72", "debian-phpfpm72", "ubuntu-phpfpm74", "debian-phpfpm74", "ubuntu-phpfpm80", "debian-phpfpm80", "ubuntu-phpfpm81", "debian-phpfpm81", "ubuntu-phpfpm82", "debian-phpfpm82", "ubuntu-phpfpm83", "debian-phpfpm83", "ubuntu-phpfpm84", "debian-phpfpm84", "ubuntu-phpfpm85", "debian-phpfpm85" ]
}

group "multiphp" {
    targets = [
        "ubuntu-multiphp", "debian-multiphp" ]
}

group "nginx" {
    targets = [
       "debian-nginx", "ubuntu-nginx" ]
}

group "angie" {
    targets = [
       "debian-angie", "ubuntu-angie" ]
}

group "angie-php" {
    targets = [
       "ubuntu-angie-php56", "debian-angie-php56", "ubuntu-angie-php72", "debian-angie-php72", "ubuntu-angie-php74", "debian-angie-php74", "ubuntu-angie-php80", "debian-angie-php80", "ubuntu-angie-php81", "debian-angie-php81", "ubuntu-angie-php82", "debian-angie-php82", "ubuntu-angie-php83", "debian-angie-php83", "ubuntu-angie-php84", "debian-angie-php84", "ubuntu-angie-php85", "debian-angie-php85", "ubuntu-angie-multi", "debian-angie-multi" ]
}

group "nginx-php" {
    targets = [
       "ubuntu-nginx-php56", "debian-nginx-php56", "ubuntu-nginx-php72", "debian-nginx-php72", "ubuntu-nginx-php74", "debian-nginx-php74", "ubuntu-nginx-php80", "debian-nginx-php80", "ubuntu-nginx-php81", "debian-nginx-php81", "ubuntu-nginx-php82", "debian-nginx-php82", "ubuntu-nginx-php83", "debian-nginx-php83", "ubuntu-nginx-php84", "debian-nginx-php84", "ubuntu-nginx-php85", "debian-nginx-php85", "ubuntu-nginx-multi", "debian-nginx-multi" ]
}

group "apache" {
    targets = [
       "debian-apache-php56", "debian-apache-php72", "debian-apache-php74", "debian-apache-php80", "debian-apache-php81", "debian-apache-php82", "debian-apache-php83", "debian-apache-php84", "debian-apache-php85", "debian-apache-multiphp", "ubuntu-apache-php56", "ubuntu-apache-php72", "ubuntu-apache-php74", "ubuntu-apache-php80", "ubuntu-apache-php81", "ubuntu-apache-php82", "ubuntu-apache-php83", "ubuntu-apache-php84", "ubuntu-apache-php85", "ubuntu-apache-multiphp" ]
}

group "apache-misc" {
    targets = [
       "debian-roundcube"
    ]
}

group "mail" {
    targets = [
       "ubuntu-postfix", "debian-postfix", "alpine-rspamd", "debian-rspamd-git", "debian-rspamd", "debian-rspamd-official", "ubuntu-rspamd", "ubuntu-dovecot", "debian-dovecot" ]
}

group "db" {
    targets = [
        "ubuntu-redis", "debian-redis", "ubuntu-valkey", "debian-valkey", "ubuntu-mariadb", "debian-mariadb" ]
}

group "misc" {
    targets = [
       "clamav", "alpine-letsencrypt", "rbldnsd", "ubuntu-reprepro", "debian-sitewarmup", "alpine-unbound", "aptly", "debian-openssh" ]
}

target "cms" {
    dockerfile = "Dockerfile-ubu"
    context = "src/docker-cms"
    tags = ["docker.io/eilandert/docker-cms:latest"]
}

target "rolling" {
    dockerfile = "Dockerfile-rolling"
    context = "src/base"
    tags = ["docker.io/eilandert/ubuntu-base:rolling"]
}

target "devel" {
    dockerfile = "Dockerfile-devel"
    context = "src/base"
    tags = ["docker.io/eilandert/ubuntu-base:devel"]
}

target "noble" {
    dockerfile = "Dockerfile-noble"
    context = "src/base"
    tags = ["docker.io/eilandert/ubuntu-base:noble"]
}

target "resolute" {
    dockerfile = "Dockerfile-resolute"
    context = "src/base"
    tags = ["docker.io/eilandert/ubuntu-base:resolute"]
}

target "jammy" {
    dockerfile = "Dockerfile-jammy"
    context = "src/base"
    tags = ["docker.io/eilandert/ubuntu-base:jammy"]
}

target "focal" {
    dockerfile = "Dockerfile-focal"
    context = "src/base"
    tags = ["docker.io/eilandert/ubuntu-base:focal"]
}

target "bionic" {
    dockerfile = "Dockerfile-bionic"
    context = "src/base"
    tags = ["docker.io/eilandert/ubuntu-base:bionic"]
}

target "xenial" {
    dockerfile = "Dockerfile-xenial"
    context = "src/base"
    tags = ["docker.io/eilandert/ubuntu-base:xenial"]
}

target "trusty" {
    dockerfile = "Dockerfile-trusty"
    context = "src/base"
    tags = ["docker.io/eilandert/ubuntu-base:trusty"]
}

target "trixie" {
    dockerfile = "Dockerfile-trixie"
    context = "src/base"
    tags = ["docker.io/eilandert/debian-base:trixie", "docker.io/eilandert/debian-base:stable"]
}

target "bookworm" {
    dockerfile = "Dockerfile-bookworm"
    context = "src/base"
    tags = ["docker.io/eilandert/debian-base:bookworm"]
}

target "bullseye" {
    dockerfile = "Dockerfile-bullseye"
    context = "src/base"
    tags = ["docker.io/eilandert/debian-base:bullseye"]
}

target "buster" {
    dockerfile = "Dockerfile-buster"
    context = "src/base"
    tags = ["docker.io/eilandert/debian-base:buster"]
}

target "stretch" {
    dockerfile = "Dockerfile-stretch"
    context = "src/base"
    tags = ["docker.io/eilandert/debian-base:stretch"]
}

target "ubuntu-phpfpm56" {
    tags = ["docker.io/eilandert/php-fpm:5.6"]
    context = "src/php-fpm"
    dockerfile = "Dockerfile-56-ubu"
    inherits = ["rolling"]
}

target "debian-phpfpm56" {
    tags = ["docker.io/eilandert/php-fpm:deb-5.6"]
    context = "src/php-fpm"
    dockerfile = "Dockerfile-56-deb"
}

target "ubuntu-phpfpm72" {
    tags = ["docker.io/eilandert/php-fpm:7.2"]
    context = "src/php-fpm"
    dockerfile = "Dockerfile-72-ubu"
}
target "debian-phpfpm72" {
    tags = ["docker.io/eilandert/php-fpm:deb-7.2"]
    context = "src/php-fpm"
    dockerfile = "Dockerfile-72-deb"
}

target "ubuntu-phpfpm74" {
    tags = ["docker.io/eilandert/php-fpm:7.4"]
    context = "src/php-fpm"
    dockerfile = "Dockerfile-74-ubu"
}

target "debian-phpfpm74" {
    tags = ["docker.io/eilandert/php-fpm:deb-7.4"]
    context = "src/php-fpm"
    dockerfile = "Dockerfile-74-deb"
}

target "ubuntu-phpfpm80" {
    tags = ["docker.io/eilandert/php-fpm:8.0", "docker.io/eilandert/php-fpm:latest"]
    context = "src/php-fpm"
    dockerfile = "Dockerfile-80-ubu"
}

target "debian-phpfpm80" {
    tags = ["docker.io/eilandert/php-fpm:deb-8.0", "docker.io/eilandert/php-fpm:deb-latest"]
    context = "src/php-fpm"
    dockerfile = "Dockerfile-80-deb"
}

target "ubuntu-phpfpm81" {
    tags = ["docker.io/eilandert/php-fpm:8.1"]
    context = "src/php-fpm"
    dockerfile = "Dockerfile-81-ubu"
}

target "debian-phpfpm81" {
    tags = ["docker.io/eilandert/php-fpm:deb-8.1"]
    context = "src/php-fpm"
    dockerfile = "Dockerfile-81-deb"
}

target "ubuntu-phpfpm82" {
    tags = ["docker.io/eilandert/php-fpm:8.2"]
    context = "src/php-fpm"
    dockerfile = "Dockerfile-82-ubu"
}

target "debian-phpfpm82" {
    tags = ["docker.io/eilandert/php-fpm:deb-8.2"]
    context = "src/php-fpm"
    dockerfile = "Dockerfile-82-deb"
}

target "ubuntu-phpfpm83" {
    tags = ["docker.io/eilandert/php-fpm:8.3"]
    context = "src/php-fpm"
    dockerfile = "Dockerfile-83-ubu"
}

target "ubuntu-phpfpm84" {
    tags = ["docker.io/eilandert/php-fpm:8.4"]
    context = "src/php-fpm"
    dockerfile = "Dockerfile-84-ubu"
}

target "debian-phpfpm83" {
    tags = ["docker.io/eilandert/php-fpm:deb-8.3"]
    context = "src/php-fpm"
    dockerfile = "Dockerfile-83-deb"
}

target "debian-phpfpm84" {
    tags = ["docker.io/eilandert/php-fpm:deb-8.4"]
    context = "src/php-fpm"
    dockerfile = "Dockerfile-84-deb"
}

target "ubuntu-phpfpm85" {
    tags = ["docker.io/eilandert/php-fpm:8.5"]
    context = "src/php-fpm"
    dockerfile = "Dockerfile-85-ubu"
}

target "debian-phpfpm85" {
    tags = ["docker.io/eilandert/php-fpm:deb-8.5"]
    context = "src/php-fpm"
    dockerfile = "Dockerfile-85-deb"
}

target "ubuntu-multiphp" {
    tags = ["docker.io/eilandert/php-fpm:multi"]
    context = "src/php-fpm"
    dockerfile = "Dockerfile-multi-ubu"
}

target "debian-multiphp" {
    tags = ["docker.io/eilandert/php-fpm:deb-multi"]
    context = "src/php-fpm"
    dockerfile = "Dockerfile-multi-deb"
}

target "debian-mariadb" {
    tags = ["docker.io/eilandert/mariadb:debian", "docker.io/eilandert/mariadb:latest"]
    context = "src/mariadb"
    dockerfile = "Dockerfile-deb"
}

target "ubuntu-mariadb" {
    tags = ["docker.io/eilandert/mariadb:ubuntu"]
    context = "src/mariadb"
    dockerfile = "Dockerfile-ubu"
}

target "debian-nginx" {
    tags = ["docker.io/eilandert/nginx-modsecurity3-pagespeed:deb-latest", "docker.io/eilandert/nginx:deb-latest"]
    context = "src/nginx"
    dockerfile = "Dockerfile-deb"
}

target "ubuntu-nginx" {
    tags = ["docker.io/eilandert/nginx-modsecurity3-pagespeed:latest"]
    context = "src/nginx"
    dockerfile = "Dockerfile-ubu"
}

target "ubuntu-nginx-php56" {
    tags = ["docker.io/eilandert/nginx-modsecurity3-pagespeed:php5.6"]
    context = "src/nginx"
    dockerfile = "Dockerfile-php56-ubu"
}

target "debian-nginx-php56" {
    tags = ["docker.io/eilandert/nginx-modsecurity3-pagespeed:deb-php5.6", "docker.io/eilandert/nginx:deb-php5.6"]
    context = "src/nginx"
    dockerfile = "Dockerfile-php56-deb"
}

target "ubuntu-nginx-php72" {
    tags = ["docker.io/eilandert/nginx-modsecurity3-pagespeed:php7.2"]
    context = "src/nginx"
    dockerfile = "Dockerfile-php72-ubu"
}

target "debian-nginx-php72" {
    tags = ["docker.io/eilandert/nginx-modsecurity3-pagespeed:deb-php7.2", "docker.io/eilandert/nginx:deb-php7.4"]
    context = "src/nginx"
    dockerfile = "Dockerfile-php72-deb"
}

target "ubuntu-nginx-php74" {
    tags = ["docker.io/eilandert/nginx-modsecurity3-pagespeed:php7.4"]
    context = "src/nginx"
    dockerfile = "Dockerfile-php74-ubu"
}

target "debian-nginx-php74" {
    tags = ["docker.io/eilandert/nginx-modsecurity3-pagespeed:deb-php7.4", "docker.io/eilandert/nginx:deb-php7.4"]
    context = "src/nginx"
    dockerfile = "Dockerfile-php74-deb"
}

target "ubuntu-nginx-php80" {
    tags = ["docker.io/eilandert/nginx-modsecurity3-pagespeed:php8.0"]
    context = "src/nginx"
    dockerfile = "Dockerfile-php80-ubu"
}

target "debian-nginx-php80" {
    tags = ["docker.io/eilandert/nginx-modsecurity3-pagespeed:deb-php8.0", "docker.io/eilandert/nginx:deb-php8.0"]
    context = "src/nginx"
    dockerfile = "Dockerfile-php80-deb"
}

target "ubuntu-nginx-php81" {
    tags = ["docker.io/eilandert/nginx-modsecurity3-pagespeed:php8.1"]
    context = "src/nginx"
    dockerfile = "Dockerfile-php81-ubu"
}

target "ubuntu-nginx-php82" {
    tags = ["docker.io/eilandert/nginx-modsecurity3-pagespeed:php8.2"]
    context = "src/nginx"
    dockerfile = "Dockerfile-php82-ubu"
}

target "ubuntu-nginx-php83" {
    tags = ["docker.io/eilandert/nginx-modsecurity3-pagespeed:php8.3"]
    context = "src/nginx"
    dockerfile = "Dockerfile-php83-ubu"
}

target "ubuntu-nginx-php84" {
    tags = ["docker.io/eilandert/nginx-modsecurity3-pagespeed:php8.4"]
    context = "src/nginx"
    dockerfile = "Dockerfile-php84-ubu"
}

target "debian-nginx-php81" {
    tags = ["docker.io/eilandert/nginx-modsecurity3-pagespeed:deb-php8.1", "docker.io/eilandert/nginx:deb-php8.1"]
    context = "src/nginx"
    dockerfile = "Dockerfile-php81-deb"
}

target "debian-nginx-php82" {
    tags = ["docker.io/eilandert/nginx-modsecurity3-pagespeed:deb-php8.2", "docker.io/eilandert/nginx:deb-php8.2"]
    context = "src/nginx"
    dockerfile = "Dockerfile-php82-deb"
}

target "debian-nginx-php83" {
    tags = ["docker.io/eilandert/nginx-modsecurity3-pagespeed:deb-php8.3", "docker.io/eilandert/nginx:deb-php8.3"]
    context = "src/nginx"
    dockerfile = "Dockerfile-php83-deb"
}

target "debian-nginx-php84" {
    tags = ["docker.io/eilandert/nginx-modsecurity3-pagespeed:deb-php8.4", "docker.io/eilandert/nginx:deb-php8.4"]
    context = "src/nginx"
    dockerfile = "Dockerfile-php84-deb"
}

target "ubuntu-nginx-php85" {
    tags = ["docker.io/eilandert/nginx-modsecurity3-pagespeed:php8.5", "docker.io/eilandert/nginx:php8.5"]
    context = "src/nginx"
    dockerfile = "Dockerfile-php85-ubu"
}

target "debian-nginx-php85" {
    tags = ["docker.io/eilandert/nginx-modsecurity3-pagespeed:deb-php8.5", "docker.io/eilandert/nginx:deb-php8.5"]
    context = "src/nginx"
    dockerfile = "Dockerfile-php85-deb"
}

target "ubuntu-nginx-multi" {
    tags = ["docker.io/eilandert/nginx-modsecurity3-pagespeed:multi"]
    context = "src/nginx"
    dockerfile = "Dockerfile-multi-ubu"
}

target "debian-nginx-multi" {
    tags = ["docker.io/eilandert/nginx-modsecurity3-pagespeed:deb-multi", "docker.io/eilandert/nginx:deb-multi"]
    context = "src/nginx"
    dockerfile = "Dockerfile-multi-deb"
}

target "debian-apache-php56" {
    tags = ["docker.io/eilandert/apache-phpfpm:deb-5.6"]
    context = "src/apache-phpfpm"
    dockerfile = "Dockerfile-56-deb"
}

target "debian-apache-php72" {
    tags = ["docker.io/eilandert/apache-phpfpm:deb-7.2"]
    context = "src/apache-phpfpm"
    dockerfile = "Dockerfile-72-deb"
}

target "debian-apache-php74" {
    tags = ["docker.io/eilandert/apache-phpfpm:deb-7.4"]
    context = "src/apache-phpfpm"
    dockerfile = "Dockerfile-74-deb"
}

target "debian-apache-php80" {
    tags = ["docker.io/eilandert/apache-phpfpm:deb-8.0", "docker.io/eilandert/apache-phpfpm:deb-latest"]
    context = "src/apache-phpfpm"
    dockerfile = "Dockerfile-80-deb"
}

target "debian-apache-php81" {
    tags = ["docker.io/eilandert/apache-phpfpm:deb-8.1"]
    context = "src/apache-phpfpm"
    dockerfile = "Dockerfile-81-deb"
}

target "debian-apache-php82" {
    tags = ["docker.io/eilandert/apache-phpfpm:deb-8.2"]
    context = "src/apache-phpfpm"
    dockerfile = "Dockerfile-82-deb"
}

target "debian-apache-php83" {
    tags = ["docker.io/eilandert/apache-phpfpm:deb-8.3"]
    context = "src/apache-phpfpm"
    dockerfile = "Dockerfile-83-deb"
}

target "debian-apache-php84" {
    tags = ["docker.io/eilandert/apache-phpfpm:deb-8.4"]
    context = "src/apache-phpfpm"
    dockerfile = "Dockerfile-84-deb"
}

target "debian-apache-php85" {
    tags = ["docker.io/eilandert/apache-phpfpm:deb-8.5"]
    context = "src/apache-phpfpm"
    dockerfile = "Dockerfile-85-deb"
}

target "debian-apache-multiphp" {
    tags = ["docker.io/eilandert/apache-phpfpm:deb-multi"]
    context = "src/apache-phpfpm"
    dockerfile = "Dockerfile-multi-deb"
}

target "ubuntu-apache-php56" {
    tags = ["docker.io/eilandert/apache-phpfpm:5.6"]
    context = "src/apache-phpfpm"
    dockerfile = "Dockerfile-56-ubu"
}

target "ubuntu-apache-php72" {
    tags = ["docker.io/eilandert/apache-phpfpm:7.2"]
    context = "src/apache-phpfpm"
    dockerfile = "Dockerfile-72-ubu"
}

target "ubuntu-apache-php74" {
    tags = ["docker.io/eilandert/apache-phpfpm:7.4"]
    context = "src/apache-phpfpm"
    dockerfile = "Dockerfile-74-ubu"
}

target "ubuntu-apache-php80" {
    tags = ["docker.io/eilandert/apache-phpfpm:8.0", "docker.io/eilandert/apache-phpfpm:latest"]
    context = "src/apache-phpfpm"
    dockerfile = "Dockerfile-80-ubu"
}

target "ubuntu-apache-php81" {
    tags = ["docker.io/eilandert/apache-phpfpm:8.1"]
    context = "src/apache-phpfpm"
    dockerfile = "Dockerfile-81-ubu"
}

target "ubuntu-apache-php82" {
    tags = ["docker.io/eilandert/apache-phpfpm:8.2"]
    context = "src/apache-phpfpm"
    dockerfile = "Dockerfile-82-ubu"
}

target "ubuntu-apache-php83" {
    tags = ["docker.io/eilandert/apache-phpfpm:8.3"]
    context = "src/apache-phpfpm"
    dockerfile = "Dockerfile-83-ubu"
}

target "ubuntu-apache-php84" {
    tags = ["docker.io/eilandert/apache-phpfpm:8.4"]
    context = "src/apache-phpfpm"
    dockerfile = "Dockerfile-84-ubu"
}

target "ubuntu-apache-php85" {
    tags = ["docker.io/eilandert/apache-phpfpm:8.5"]
    context = "src/apache-phpfpm"
    dockerfile = "Dockerfile-85-ubu"
}

target "ubuntu-apache-multiphp" {
    tags = ["docker.io/eilandert/apache-phpfpm:multi"]
    context = "src/apache-phpfpm"
    dockerfile = "Dockerfile-multi-ubu"
}

target "clamav" {
   tags = ["docker.io/eilandert/clamav-unofficial-sigs"]
   context = "src/clamav-unofficial-signatures"
   dockerfile = "Dockerfile-ubu"
}

target "ubuntu-dovecot" {
   tags = ["docker.io/eilandert/dovecot:ubuntu", "docker.io/eilandert/dovecot:latest"]
   context = "src/dovecot-ubuntu"
   dockerfile = "Dockerfile-ubu"
}

target "debian-dovecot" {
   tags = ["docker.io/eilandert/dovecot:debian"]
   context = "src/dovecot-ubuntu"
   dockerfile = "Dockerfile-deb"
}

target "alpine-letsencrypt" {
   tags = ["docker.io/eilandert/letsencrypt"]
   context = "src/letsencrypt"
   dockerfile = "Dockerfile-ubu"
}

target "ubuntu-postfix" {
   tags = ["docker.io/eilandert/postfix:ubuntu", "docker.io/eilandert/postfix:latest"]
   context = "src/postfix"
   dockerfile = "Dockerfile-ubu"
}

target "debian-postfix" {
   tags = ["docker.io/eilandert/postfix:debian"]
   context = "src/postfix"
   dockerfile = "Dockerfile-deb"
}

target "rbldnsd" {
   tags = ["docker.io/eilandert/rbldnsd"]
   context = "src/rbldnsd"
   dockerfile = "Dockerfile-ubu"
}

target "alpine-redis" {
   tags = ["docker.io/eilandert/redis:scratch"]
   context = "src/redis6-scratch"
   dockerfile = "Dockerfile-ubu"
}

target "ubuntu-redis" {
   tags = ["docker.io/eilandert/redis:ubuntu"]
   context = "src/redis"
   dockerfile = "Dockerfile-ubu"
}

target "debian-redis" {
   tags = ["docker.io/eilandert/redis:debian"]
   context = "src/redis"
   dockerfile = "Dockerfile-deb"
}

target "ubuntu-valkey" {
   tags = ["docker.io/eilandert/valkey:ubuntu"]
   context = "src/valkey"
   dockerfile = "Dockerfile-ubu"
}

target "debian-valkey" {
   tags = ["docker.io/eilandert/valkey:debian"]
   context = "src/valkey"
   dockerfile = "Dockerfile-deb"
}

target "ubuntu-reprepro" {
   tags = ["docker.io/eilandert/reprepro"]
   context = "src/reprepro"
   dockerfile = "Dockerfile-ubu"
}

target "ubuntu-roundcube" {
   tags = ["docker.io/eilandert/roundcube:ubuntu"]
   context = "src/roundcube"
   dockerfile = "Dockerfile-ubuntu"
}

target "debian-roundcube" {
   tags = ["docker.io/eilandert/roundcube:debian", "docker.io/eilandert/roundcube:latest"]
   context = "src/roundcube"
   dockerfile = "Dockerfile-deb"
}

target "alpine-rspamd" {
   tags = ["docker.io/eilandert/rspamd"]
   context = "src/rspamd"
   dockerfile = "Dockerfile-ubu"
}

target "debian-rspamd-git" {
   tags = ["docker.io/eilandert/rspamd-git:latest"]
   context = "src/rspamd-git"
   dockerfile = "Dockerfile-ubu"
}
target "debian-rspamd-official" {
   tags = ["docker.io/eilandert/rspamd-git:official"]
   context = "src/rspamd-git"
   dockerfile = "Dockerfile-official"
}

target "debian-rspamd" {
   tags = ["docker.io/eilandert/rspamd-git:debian", "docker.io/eilandert/rspamd-git:release"]
   context = "src/rspamd-git"
   dockerfile = "Dockerfile-deb"
}
target "ubuntu-rspamd" {
   tags = ["docker.io/eilandert/rspamd-git:ubuntu"]
   context = "src/rspamd-git"
   dockerfile = "Dockerfile-stable"
}
target "debian-sitewarmup" {
   tags = ["docker.io/eilandert/sitemap_warmup"]
   context = "src/sitemap_warmup"
   dockerfile = "Dockerfile-ubu"
}
target "alpine-unbound" {
   tags = ["docker.io/eilandert/unbound"]
   context = "src/unbound"
   dockerfile = "Dockerfile-ubu"
}
target "alpine-vimbadmin" {
   tags = ["docker.io/eilandert/vimbadmin:alpine"]
   context = "src/vimbadmin"
   dockerfile = "Dockerfile-ubu"
}
target "debian-vimbadmin" {
   tags = ["docker.io/eilandert/vimbadmin:debian", "docker.io/eilandert/vimbadmin:latest"]
   context = "src/vimbadmin-ubuntu"
   dockerfile = "Dockerfile-deb"
}
target "ubuntu-vimbadmin" {
   tags = ["docker.io/eilandert/vimbadmin:ubuntu"]
   context = "src/vimbadmin-ubuntu"
   dockerfile = "Dockerfile-ubu"
}
target "psol" {
   tags = ["docker.io/eilandert/psol"]
   context = "src/psol-build"
   dockerfile = "Dockerfile-ubu"
}

target "debian-openssh" {
   tags = ["docker.io/eilandert/openssh:debian"]
   context = "src/openssh"
   dockerfile = "Dockerfile-deb"
}

target "aptly" {
   tags = ["docker.io/eilandert/aptly"]
   context = "src/aptly"
   dockerfile = "Dockerfile-ubu"
}

target "debian-angie" {
    tags = ["docker.io/eilandert/angie:deb-latest"]
    context = "src/angie"
    dockerfile = "Dockerfile-deb"
}

target "ubuntu-angie" {
    tags = ["docker.io/eilandert/angie:latest"]
    context = "src/angie"
    dockerfile = "Dockerfile-ubu"
}

target "ubuntu-angie-php56" {
    tags = ["docker.io/eilandert/angie:php5.6"]
    context = "src/angie"
    dockerfile = "Dockerfile-php56-ubu"
}

target "debian-angie-php56" {
    tags = ["docker.io/eilandert/angie:deb-php5.6"]
    context = "src/angie"
    dockerfile = "Dockerfile-php56-deb"
}

target "ubuntu-angie-php72" {
    tags = ["docker.io/eilandert/angie:php7.2"]
    context = "src/angie"
    dockerfile = "Dockerfile-php72-ubu"
}

target "debian-angie-php72" {
    tags = ["docker.io/eilandert/angie:deb-php7.2"]
    context = "src/angie"
    dockerfile = "Dockerfile-php72-deb"
}

target "ubuntu-angie-php74" {
    tags = ["docker.io/eilandert/angie:php7.4"]
    context = "src/angie"
    dockerfile = "Dockerfile-php74-ubu"
}

target "debian-angie-php74" {
    tags = ["docker.io/eilandert/angie:deb-php7.4"]
    context = "src/angie"
    dockerfile = "Dockerfile-php74-deb"
}

target "ubuntu-angie-php80" {
    tags = ["docker.io/eilandert/angie:php8.0"]
    context = "src/angie"
    dockerfile = "Dockerfile-php80-ubu"
}

target "debian-angie-php80" {
    tags = ["docker.io/eilandert/angie:deb-php8.0"]
    context = "src/angie"
    dockerfile = "Dockerfile-php80-deb"
}

target "ubuntu-angie-php81" {
    tags = ["docker.io/eilandert/angie:php8.1"]
    context = "src/angie"
    dockerfile = "Dockerfile-php81-ubu"
}

target "ubuntu-angie-php82" {
    tags = ["docker.io/eilandert/angie:php8.2"]
    context = "src/angie"
    dockerfile = "Dockerfile-php82-ubu"
}

target "ubuntu-angie-php83" {
    tags = ["docker.io/eilandert/angie:php8.3"]
    context = "src/angie"
    dockerfile = "Dockerfile-php83-ubu"
}

target "ubuntu-angie-php84" {
    tags = ["docker.io/eilandert/angie:php8.4"]
    context = "src/angie"
    dockerfile = "Dockerfile-php84-ubu"
}

target "ubuntu-angie-php85" {
    tags = ["docker.io/eilandert/angie:php8.5"]
    context = "src/angie"
    dockerfile = "Dockerfile-php85-ubu"
}

target "debian-angie-php81" {
    tags = ["docker.io/eilandert/angie:deb-php8.1"]
    context = "src/angie"
    dockerfile = "Dockerfile-php81-deb"
}

target "debian-angie-php82" {
    tags = ["docker.io/eilandert/angie:deb-php8.2"]
    context = "src/angie"
    dockerfile = "Dockerfile-php82-deb"
}
target "debian-angie-php83" {
    tags = ["docker.io/eilandert/angie:deb-php8.3"]
    context = "src/angie"
    dockerfile = "Dockerfile-php83-deb"
}

target "debian-angie-php84" {
    tags = ["docker.io/eilandert/angie:deb-php8.4"]
    context = "src/angie"
    dockerfile = "Dockerfile-php84-deb"
}

target "debian-angie-php85" {
    tags = ["docker.io/eilandert/angie:deb-php8.5"]
    context = "src/angie"
    dockerfile = "Dockerfile-php85-deb"
}

target "ubuntu-angie-multi" {
    tags = ["docker.io/eilandert/angie:multi"]
    context = "src/angie"
    dockerfile = "Dockerfile-multi-ubu"
}

target "debian-angie-multi" {
    tags = ["docker.io/eilandert/angie:deb-multi"]
    context = "src/angie"
    dockerfile = "Dockerfile-multi-deb"
}

