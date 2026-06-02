# FastCGI params for ViMbAdmin -> php-fpm 8.5 (unix socket from the pool).
include             /etc/angie/fastcgi_params;
fastcgi_pass        unix:/run/php/vimbadmin-fpm.sock;
fastcgi_index       index.php;
fastcgi_param       SCRIPT_FILENAME  $document_root$fastcgi_script_name;
fastcgi_param       APPLICATION_ENV  docker;
fastcgi_hide_header X-Powered-By;
fastcgi_read_timeout 130s;
fastcgi_buffers      16 16k;
fastcgi_buffer_size  32k;
