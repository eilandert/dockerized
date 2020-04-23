Dockerized NGINX+MODSECURITY3+GOOGLE PAGESPEED

https://launchpad.net/~eilander/+archive/ubuntu/nginx

https://github.com/eilandert/dockerized/tree/master/nginx-proxy-modsecurity-pagespeed

https://hub.docker.com/r/eilandert/nginx-modsecurity3-pagespeed

Features:
 * Latest Mainline. (and not stable).
 * Removed ubuntu branding in server signature
 * Build with AIO support (better performance for eg ZFS)
 * Added configuration for SSL Early Data
 * Added HTTP2 HPACK Encoding Support. (cloudflare patch)
 * Added patch to reduce Time To First Byte in TLS Handshake (cloudflare patch)

ander other stuff

Extra packages:
 * Added gitversion of mod-security v3.0.4
 * Added gitversion of the libmodsecurity3 connector
 * Added gitversion of google pagespeed module, https://www.modpagespeed.com/doc/
 * Added gitversion of ngx_brotli
