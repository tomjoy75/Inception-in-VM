FROM debian:bullseye
RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y curl php php7.4-fpm php-mysql mariadb-client php-redis redis-tools unzip procps msmtp msmtp-mta
    # Install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

RUN rm -rf /var/lib/apt/lists/*

# Configure PHP-FPM
RUN sed -i 's/listen = .*/listen = 9000/g' /etc/php/7.4/fpm/pool.d/www.conf && \
    mkdir -p /run/php && \
    # Fix PHP-FPM configuration
    echo "\
[www]\n\
pm = dynamic\n\
pm.max_children = 5\n\
pm.start_servers = 2\n\
pm.min_spare_servers = 1\n\
pm.max_spare_servers = 3\n\
listen = 9000\n\
clear_env = no\n\
" > /etc/php/7.4/fpm/pool.d/www.conf

# Configure mail
RUN echo "sendmail_path = /usr/bin/msmtp -t" >> /etc/php/7.4/fpm/php.ini

# Create WordPress directory
RUN mkdir -p /var/www/wordpress && \
    chown -R www-data:www-data /var/www/wordpress

WORKDIR /var/www/wordpress
COPY ./conf/wp_conf.sh /
RUN chmod +x /wp_conf.sh

# Healthcheck to verify PHP-FPM is running
HEALTHCHECK --interval=10s --timeout=5s --start-period=30s --retries=3 \
    CMD pgrep php-fpm7.4 || exit 1

ENTRYPOINT ["/wp_conf.sh"]