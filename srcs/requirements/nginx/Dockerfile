FROM debian:bullseye
RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y nginx openssl

RUN mkdir -p /etc/nginx/ssl
RUN openssl req -x509 -nodes -out /etc/nginx/ssl/inception.crt -keyout \
    /etc/nginx/ssl/inception.key -subj "/C=FR/ST=Paris/L=Paris/O=42/OU=42/CN=tjoyeux.42.fr/UID=admin_name"

COPY ./conf/nginx.conf /etc/nginx/nginx.conf
RUN mkdir -p /var/www/wordpress
RUN chown -R www-data:www-data /var/www/wordpress

RUN mkdir -p /etc/nginx/conf.d
COPY ./conf/bonus/adminer.conf /etc/nginx/conf.d/adminer.conf.disabled

RUN mkdir -p /tools
COPY ./tools/docker-entrypoint.sh /tools/docker-entrypoint.sh
RUN chmod +x /tools/docker-entrypoint.sh

ENTRYPOINT ["/tools/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]