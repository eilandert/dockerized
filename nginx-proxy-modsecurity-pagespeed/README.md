Dockerized NGINX+MODSECURITY3+GOOGLE PAGESPEED


This docker can be found on [Github](https://github.com/eilandert/dockerized/tree/master/nginx-proxy-modsecurity-pagespeed) and [Dockerhub](https://hub.docker.com/r/eilandert/nginx-modsecurity3-pagespeed)

And complete packages on [Launchpad](https://launchpad.net/~eilander/+archive/ubuntu/nginx)


Features:
 * Latest Mainline. (and not stable).
 * Removed ubuntu branding in server signature
 * Compiled with -O3 -flto to squeeze some extra % performance.
 * Build with file AIO support (better performance for eg ZFS)
 * Linked all builds against OpenSSL 1.1.1g so there is ALPN and TLS1.3 support
 * Added /etc/nginx/snippets/ssl.conf.example, should give A+ on SSLLABS

Patches:
 * Added HTTP2 HPACK Encoding Support. (Cloudflare patch)
 * Added Optimizing TLS over TCP to reduce latency (Cloudflare patch)
   (add ssl_dyn_rec_enable on; to the http{} block)

Extra NGINX packages build from git: (besides the packages included with ubuntu)
 * libnginx-mod-brotli - NGINX module for Brotli compression
         (https://github.com/google/ngx_brotli)
 * libnginx-mod-naxsi - NAXSI is an open-source WAF for NGINX
         (https://github.com/nbs-system/naxsi)
 * libnginx-mod-security-headers NGINX Module for sending security headers
         (https://github.com/GetPageSpeed/ngx_security_headers)
 * libnginx-mod-ssl-ct Certificate Transparency module for nginx.
         (https://github.com/grahamedgecombe/nginx-ct)
 * libnginx-mod-modsecurity connector for libmodsecurity3
         (https://github.com/SpiderLabs/ModSecurity-nginx)
 * libnginx-mod-pagespeed ngx_pagespeed speeds up your site
         (https://www.modpagespeed.com/doc/)

Standalone Libraries:
 * libmodsecurity3 - ModSecurity v3 library component
 * modsecurity-crs - OWASP ModSecurity Core Rule Set https://coreruleset.org

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

If you like my packages, please consider a small donation at
paypal nomad @ paranoid.nl
