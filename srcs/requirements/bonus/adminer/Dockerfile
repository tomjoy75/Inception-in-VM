FROM debian:bullseye
RUN apt-get update && apt-get upgrade -y 
RUN apt-get install -y adminer php7.4-fpm php7.4-mysql
RUN rm -rf /var/lib/apt/lists/*
RUN mkdir -p /var/www/html && cp /usr/share/adminer/adminer.php /var/www/html/index.php
EXPOSE 8080
CMD ["php", "-S", "0.0.0.0:8080", "-t", "/var/www/html"]