Dockerized NGINX+MODSECURITY3+GOOGLE PAGESPEED - This docker can be found on 
**[Github](https://github.com/eilandert/dockerized/tree/master/nginx-proxy-modsecurity-pagespeed)** and 
**[Dockerhub](https://hub.docker.com/r/eilandert/nginx-modsecurity3-pagespeed)** **Complete packages and description are on my 
[PPA](http://deb.paranoid.nl/pages/nginx.html)** PHP packages are from **[Ondrejs excellent 
PPA](https://launchpad.net/~ondrej/+archive/ubuntu/php)** Tags: - eilandert/nginx-modsecurity3-pagespeed:latest (without php, nullmailer 
or composer) - eilandert/nginx-modsecurity3-pagespeed:multi (with all versions of php, nullmailer and composer) - 
eilandert/nginx-modsecurity3-pagespeed:php5.6 (with php5.6, nullmailer and composer) - eilandert/nginx-modsecurity3-pagespeed:php7.2 (with 
php7.2, nullmailer and composer) - eilandert/nginx-modsecurity3-pagespeed:php7.4 (with php7.4, nullmailer and composer) - 
eilandert/nginx-modsecurity3-pagespeed:php8.0 (with php8.0, nullmailer and composer) All based on eilandert/ubuntu-base:rolling.  If there 
is need to have debian packages I am up for it, but there is no demand of as yet. For the tag with multi, you can enable different 
versions with PHP56=YES PHP72=YES PHP74=YES and PHP80=YES Socket will be made in /run/php/php7.4-fpm.sock or whatever version you enabled. 
Bind /etc/nginx and /etc/modsecurity (for php, /etc/nullmailer and /etc/php) to an empty local directory and it will be populated on first 
run with default configs. See my github for an example of 
**[docker-compose.yml](https://github.com/eilandert/dockerized/blob/master/nginx-proxy-modsecurity-pagespeed/docker-compose.yml)** I am 
open to suggestions! ORIGINAL DESCRIPTION - This is a complete nginx stack based on an updated rebuild/backport of the Ubuntu-20.10 Groovy 
NGINX Package with latest OpenSSL (1.1.1k at time of writing) **Packages are on https://deb.paranoid.nl** Goal is to have a full fledged 
http proxy/ssl terminator for my minimal configured lxc/docker/wordpress/magento/opencart instances while keeping security and performance 
in mind. Building this repo is the easiest way to keep it altogether and up2date in the debian/ubuntu way. I don't personally use all 
modules, some are requested by readers like you. updates: - builds are now automated. - the modsecurity core ruleset (crs, from git) is 
rebuilt once a week - dependencies like libmaxminddb, libbrotli and libmodsecurity3 will rebuild from git on new release. - nginx (and all 
modules) rebuilds when a new version is released, except when it breaks patches which I will try to fix manually as soon as possible. - 
the Pagespeed Library (PSOL) is now build per distro once a week - **There is an docker image on 
[https://hub.docker.com/r/eilandert/nginx-modsecurity3-pagespeed](https://hub.docker.com/r/eilandert/nginx-modsecurity3-pagespeed)** 
Currently the automated builds are available for: Debian Bullseye, Buster and Stretch Ubuntu Bionic, Focal and rolling/devel I will try to 
support the last two LTS/Stable versions and earlier but will remove them if it gets too difficult to keep supporting it. Features: - 
Latest Mainline. (and not stable). - Removed ubuntu branding in server signature - Optimized nginx.conf - Compiled with -O3 -flto to 
squeeze some extra % performance. - Build with file AIO support (better performance for eg ZFS) - Linked all builds (except for stretch) 
against OpenSSL 1.1.1k (at time of writing) so there is ALPN and TLS1.3 support - Added /etc/nginx/snippets/ssl.conf.example, should give 
A+ on SSLLABS - Added [https://ssl-config.mozilla.org/ffdhe4096.txt](https://ssl-config.mozilla.org/ffdhe4096.txt) as dhparams.pem (ssl) - 
Added additional security in snippets/ - Added maps against bots in snippets/ - Added some hardening in snippets/ - Added proxy.conf in 
snippets/ - Pagespeed: Seperately PSOL libraries per distro, build once a week. - Added some performance in snippets/ (or it will, in a 
new build) (Some of the snippets are inspired on [https://calomel.org/nginx.html](https://calomel.org/nginx.html)) Patches: - Added HTTP2 
HPACK Encoding Support. (Cloudflare patch) - Added Optimizing TLS over TCP to reduce latency (Cloudflare patch) (add ssl_dyn_rec_enable 
on; to the http{} block) Standalone Libraries: - libmodsecurity3 - ModSecurity v3 library component for use with the NGINX connector - 
modsecurity-crs - OWASP ModSecurity Core Rule Set [https://coreruleset.org](https://coreruleset.org/) Extra NGINX packages build from git: 
(besides the packages included with ubuntu) - libnginx-mod-pagespeed ngx_pagespeed speeds up your site
    ``` (https://www.modpagespeed.com/doc/) ``` - libnginx-mod-modsecurity connector for libmodsecurity3 ``` 
      (https://github.com/SpiderLabs/ModSecurity-nginx)
    ```
    
- libnginx-mod-security-headers NGINX Module for sending security headers ``` (https://github.com/GetPageSpeed/ngx_security_headers) ``` - 
libnginx-mod-brotli - NGINX module for Brotli compression
    ``` (https://github.com/google/ngx_brotli) ```
    
- libnginx-mod-naxsi - NAXSI is an open-source WAF for NGINX ``` (https://github.com/nbs-system/naxsi) ``` - libnginx-mod-ssl-ct 
    Certificate Transparency module for nginx.
    
    ``` (https://github.com/grahamedgecombe/nginx-ct) ```
 
 Including default Ubuntu Groovy packages: - libnginx-mod-http-auth-pam PAM authentication module for Nginx - 
libnginx-mod-http-cache-purge Purge content from Nginx caches - libnginx-mod-http-dav-ext WebDAV missing commands support for Nginx - 
libnginx-mod-http-echo Bring echo and more shell style goodies to Nginx - libnginx-mod-http-fancyindex Fancy indexes module for the Nginx 
- libnginx-mod-http-geoip GeoIP HTTP module for Nginx - libnginx-mod-http-geoip2 GeoIP2 HTTP module for Nginx - 
libnginx-mod-http-headers-more-filter Set and clear input and output headers - libnginx-mod-http-image-filter HTTP image filter module for 
Nginx - libnginx-mod-http-lua Lua module for Nginx - libnginx-mod-http-ndk Nginx Development Kit module - libnginx-mod-http-perl Perl 
module for Nginx - libnginx-mod-http-subs-filter Substitution filter module for Nginx - libnginx-mod-http-uploadprogress Upload progress 
system for Nginx - libnginx-mod-http-upstream-fair Nginx Upstream Fair Proxy Load Balancer - libnginx-mod-http-xslt-filter XSLT 
Transformation module for Nginx - libnginx-mod-mail Mail module for Nginx - libnginx-mod-nchan Fast, flexible pub/sub server for Nginx - 
libnginx-mod-rtmp RTMP support for Nginx - libnginx-mod-stream Stream module for Nginx - libnginx-mod-stream-geoip GeoIP Stream module for 
Nginx
-   libnginx-mod-stream-geoip2 GeoIP2 Stream module for Nginx
