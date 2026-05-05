A simple letsencrypt container (beta)

Just run the container, it tries to update the certs and waits one day to do a renew again.

See the docker-compose.yml for some examples

To request a new certificate
docker exec -it letsencrypt certbot certonly

if choosing webroot, choose /var/www/html

Two ways to use letsencrypt in normal mode:

1. as webroot.

mount a common dir for the certs in both the letsencryptcontainer and a webserver.
mount a common dir in both the letsencryptcontainer (/var/www/html) and a webserver for the webrequests. Make sure your webservers has a locationblock for letsencrypt like this:

nginx:
location ^~ /.well-known/acme-challenge/ {
default_type "text/plain";
root /var/www/html;
return 404;  
}

2. as standalone.

Use the ports 80 and 443. If you run a webserver you have to shut that down first and restart it when letsencrypt is finished

mount a common dir for the certs in both the letsencryptcontainer and a webserver.
