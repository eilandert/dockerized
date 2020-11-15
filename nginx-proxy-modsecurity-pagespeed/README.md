Dockerized NGINX+MODSECURITY3+GOOGLE PAGESPEED

This docker can be found on [Github](https://github.com/eilandert/dockerized/tree/master/nginx-proxy-modsecurity-pagespeed) and [Dockerhub](https://hub.docker.com/r/eilandert/nginx-modsecurity3-pagespeed)

Complete packages are on [Launchpad](https://launchpad.net/~eilander/+archive/ubuntu/nginx)

Tags:

- eilandert/eilandert/nginx-modsecurity3-pagespeed:latest (without php and without nullmailer)
- eilandert/eilandert/nginx-modsecurity3-pagespeed:multi (with all version of php and nullmailer)
- eilandert/eilandert/nginx-modsecurity3-pagespeed:5.6 (with php5.6 and nullmailer)
- eilandert/eilandert/nginx-modsecurity3-pagespeed:7.2 (with php7.2 and nullmailer)
- eilandert/eilandert/nginx-modsecurity3-pagespeed:7.4 (with php7.4 and nullmailer)
- eilandert/eilandert/nginx-modsecurity3-pagespeed:8.0 (with php8.0 and nullmailer)

For the tag with multi, you can enable different versions with PHP56=YES PHP72=YES PHP74=YES and PHP80=YES<BR>
Socket will be made in /run/php/php7.4-fpm.sock or whatever version you enabled.<BR>
PHP-FPM packages are from [Ondrejs excellent php ppa](https://launchpad.net/~ondrej/+archive/ubuntu/php)

Bind /etc/nginx and /etc/modsecurity (for php, /etc/nullmailer and /etc/php) to an empty local directory and it will be populated on first run with default configs.

See my github for an example of [docker-compose.yml](https://github.com/eilandert/dockerized/blob/master/nginx-proxy-modsecurity-pagespeed/docker-compose.yml)

Features:

- Latest Mainline. (and not stable).
- Removed ubuntu branding in server signature
- Optimized nginx.conf
- Compiled with -O3 -flto to squeeze some extra % performance.
- Build with file AIO support (better performance for eg ZFS)
- Linked all builds against OpenSSL 1.1.1h so there is ALPN and TLS1.3 support
- Added /etc/nginx/snippets/ssl.conf.example, should give A+ on SSLLABS
- Added https://ssl-config.mozilla.org/ffdhe4096.txt as dhparams.pem (ssl)
- Added additional security in snippets/
- Added maps against bots in snippets/
- Added some hardening in snippets/
- Added proxy.conf in snippets/
- Added some performance in snippets/ (or it will, in a new build)

Patches:

- Added HTTP2 HPACK Encoding Support. (Cloudflare patch)
- Added Optimizing TLS over TCP to reduce latency (Cloudflare patch)
  (add ssl_dyn_rec_enable on; to the http{} block)

Extra NGINX packages build from git: (besides the packages included with ubuntu)

- [libnginx-mod-brotli](https://github.com/google/ngx_brotli) - NGINX module for Brotli compression
- [libnginx-mod-naxsi](https://github.com/nbs-system/naxsi) - NAXSI is an open-source WAF for NGINX
- [libnginx-mod-security-headers](https://github.com/GetPageSpeed/ngx_security_headers) NGINX Module for sending security headers
- [libnginx-mod-ssl-ct](https://github.com/grahamedgecombe/nginx-ct) - Certificate Transparency module for nginx.
- [libnginx-mod-modsecurity](https://github.com/SpiderLabs/ModSecurity-nginx) connector for libmodsecurity3
- [libnginx-mod-pagespeed](https://www.modpagespeed.com/doc/) ngx_pagespeed speeds up your site

Standalone Libraries:

- libmodsecurity3 - ModSecurity v3 library component
- [modsecurity-crs](https://coreruleset.org) - OWASP ModSecurity Core Rule Set

Including default Ubuntu Groovy packages:

- libnginx-mod-http-auth-pam PAM authentication module for Nginx
- libnginx-mod-http-cache-purge Purge content from Nginx caches
- libnginx-mod-http-dav-ext WebDAV missing commands support for Nginx
- libnginx-mod-http-echo Bring echo and more shell style goodies to Nginx
- libnginx-mod-http-fancyindex Fancy indexes module for the Nginx
- libnginx-mod-http-geoip GeoIP HTTP module for Nginx
- libnginx-mod-http-geoip2 GeoIP2 HTTP module for Nginx
- libnginx-mod-http-headers-more-filter Set and clear input and output headers
- libnginx-mod-http-image-filter HTTP image filter module for Nginx
- libnginx-mod-http-lua Lua module for Nginx
- libnginx-mod-http-ndk Nginx Development Kit module
- libnginx-mod-http-perl Perl module for Nginx
- libnginx-mod-http-subs-filter Substitution filter module for Nginx
- libnginx-mod-http-uploadprogress Upload progress system for Nginx
- libnginx-mod-http-upstream-fair Nginx Upstream Fair Proxy Load Balancer
- libnginx-mod-http-xslt-filter XSLT Transformation module for Nginx
- libnginx-mod-mail Mail module for Nginx
- libnginx-mod-nchan Fast, flexible pub/sub server for Nginx
- libnginx-mod-rtmp RTMP support for Nginx
- libnginx-mod-stream Stream module for Nginx
- libnginx-mod-stream-geoip GeoIP Stream module for Nginx
- libnginx-mod-stream-geoip2 GeoIP2 Stream module for Nginx
