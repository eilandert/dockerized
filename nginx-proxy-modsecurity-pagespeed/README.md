Dockerized NGINX+MODSECURITY3+GOOGLE PAGESPEED

This docker can be found on [Github](https://github.com/eilandert/dockerized/tree/master/nginx-proxy-modsecurity-pagespeed) and [Dockerhub](https://hub.docker.com/r/eilandert/nginx-modsecurity3-pagespeed)

Complete packages are on [Launchpad](https://launchpad.net/~eilander/+archive/ubuntu/nginx)

Tags:
 * eilandert/eilandert/nginx-modsecurity3-pagespeed:latest  (without PHP and without nullmailer)
 * eilandert/eilandert/nginx-modsecurity3-pagespeed:php (with PHP and nullmailer, see below)

For the tag with PHP, you can enable different versions with PHP56=yes PHP74=yes and PHP80=yes<BR>
Socket will be made in /run/php/php7.4-fpm.sock or whatever version you enabled.

Bind /etc/nginx and /etc/modsecurity (for php, /etc/nullmailer and /etc/php) to an empty local directory and it will be populated on first run with default configs.

Features:
 * Latest Mainline. (and not stable).
 * Removed ubuntu branding in server signature
 * Compiled with -O3 -flto to squeeze some extra % performance.
 * Build with file AIO support (better performance for eg ZFS)
 * Linked all builds against OpenSSL 1.1.1h so there is ALPN and TLS1.3 support
 * Added /etc/nginx/snippets/ssl.conf.example, should give A+ on SSLLABS

Patches:
 * Added HTTP2 HPACK Encoding Support. (Cloudflare patch)
 * Added Optimizing TLS over TCP to reduce latency (Cloudflare patch)
   (add ssl_dyn_rec_enable on; to the http{} block)

Extra NGINX packages build from git: (besides the packages included with ubuntu)
 * [libnginx-mod-brotli](https://github.com/google/ngx_brotli) - NGINX module for Brotli compression
 * [libnginx-mod-naxsi](https://github.com/nbs-system/naxsi) - NAXSI is an open-source WAF for NGINX
 * [libnginx-mod-security-headers](https://github.com/GetPageSpeed/ngx_security_headers) NGINX Module for sending security headers
 * [libnginx-mod-ssl-ct](https://github.com/grahamedgecombe/nginx-ct) - Certificate Transparency module for nginx.
 * [libnginx-mod-modsecurity](https://github.com/SpiderLabs/ModSecurity-nginx) connector for libmodsecurity3
 * [libnginx-mod-pagespeed](https://www.modpagespeed.com/doc/) ngx_pagespeed speeds up your site

Standalone Libraries:
 * libmodsecurity3 - ModSecurity v3 library component
 * [modsecurity-crs](https://coreruleset.org) - OWASP ModSecurity Core Rule Set 

Including default Ubuntu Groovy packages:
 * libnginx-mod-http-auth-pam PAM authentication module for Nginx
 * libnginx-mod-http-cache-purge Purge content from Nginx caches
 * libnginx-mod-http-dav-ext WebDAV missing commands support for Nginx
 * libnginx-mod-http-echo Bring echo and more shell style goodies to Nginx
 * libnginx-mod-http-fancyindex Fancy indexes module for the Nginx
 * libnginx-mod-http-geoip GeoIP HTTP module for Nginx
 * libnginx-mod-http-geoip2 GeoIP2 HTTP module for Nginx
 * libnginx-mod-http-headers-more-filter Set and clear input and output headers
 * libnginx-mod-http-image-filter HTTP image filter module for Nginx
 * libnginx-mod-http-lua Lua module for Nginx
 * libnginx-mod-http-ndk Nginx Development Kit module
 * libnginx-mod-http-perl Perl module for Nginx
 * libnginx-mod-http-subs-filter Substitution filter module for Nginx
 * libnginx-mod-http-uploadprogress Upload progress system for Nginx
 * libnginx-mod-http-upstream-fair Nginx Upstream Fair Proxy Load Balancer
 * libnginx-mod-http-xslt-filter XSLT Transformation module for Nginx
 * libnginx-mod-mail Mail module for Nginx
 * libnginx-mod-nchan Fast, flexible pub/sub server for Nginx
 * libnginx-mod-rtmp RTMP support for Nginx
 * libnginx-mod-stream Stream module for Nginx
 * libnginx-mod-stream-geoip GeoIP Stream module for Nginx
 * libnginx-mod-stream-geoip2 GeoIP2 Stream module for Nginx


