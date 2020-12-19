Dockerized vimbadmin image based on eilandert/apache-phpfpm (ubuntu:rolling), apache2 and php8.x

steps:

1. log in to mysql and create user/database.

CREATE DATABASE `vimbadmin`;

GRANT ALL ON `vimbadmin`.\* TO `vimbadmin`@`ipaddress` IDENTIFIED BY 'password';

FLUSH PRIVILEGES;

2. Load the .sql file into the database. (it's on my github, in EXAMPLES).

3. bind /opt/vimbadmin/application/configs to ./config

4. start the container for the first time, it will populate ./config with application.ini AND a relevant piece of httpd.conf

5. point your reverse proxy or your browser to port 80 (or whatever port you map), in your browser use /vimbadmin

6. happy setupping
