
Apache + PHP-FPM (packages from https://launchpad.net/~ondrej)

A docker I created for serving wordpress behind a nginx proxy with caching, mod-security and pagespeed. 
But I guess you could do anything with it. 

It includes nullmailer.

Bind /etc/php, /etc/apache2 and /etc/nullmailer to a local dir, it will be populated on first run. See docker-compose.yml for examples.

I am open for suggestions.
