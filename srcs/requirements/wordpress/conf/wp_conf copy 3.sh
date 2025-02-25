#!/bin/bash

# WordPress installation setup
wp-cli_install() {
	# Download wp-cli
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    mv wp-cli.phar /usr/local/bin/wp

	# Create WP-CLI configuration directory
    mkdir -p /root/.wp-cli
    chmod 755 /root/.wp-cli

    # Create WP-CLI config file
    cat > /root/.wp-cli/config.yml << EOF
path: /var/www/wordpress
apache_modules:
  - mod_rewrite
core config:
  dbhost: mariadb:3306
  dbcharset: utf8
EOF
	# Verify installation
    if ! wp --info > /dev/null 2>&1; then
        echo "❌ WP-CLI installation failed"
        exit 1
    fi
    echo "✅ WP-CLI installed successfully"
}

# Initialize WordPress directory
wordpress_setup() {
    cd /var/www/wordpress
    chmod -R 755 /var/www/wordpress/
    chown -R www-data:www-data /var/www/wordpress
}

# Main installation process
wp-cli_install
wordpress_setup

# Download and configure WordPress
wp core download --allow-root
wp core config --dbhost=mariadb:3306 --dbname="$MYSQL_DB" --dbuser="$MYSQL_USER" --dbpass="$MYSQL_PASSWORD" --allow-root

# Install WordPress
wp core install --url="$DOMAIN_NAME" --title="$WP_TITLE" --admin_user="$WP_ADMIN_N" --admin_password="$WP_ADMIN_P" --admin_email="$WP_ADMIN_E" --allow-root
wp user create "$WP_U_NAME" "$WP_U_EMAIL" --user_pass="$WP_U_PASS" --role="$WP_U_ROLE" --allow-root

# Redis configuration and setup
if [ "$ENABLE_BONUS" = "true" ]; then
    echo "🔄 Setting up Redis..."
    
    # # Install Redis plugin
    # cd /var/www/wordpress/wp-content/plugins/
    # curl -LO https://downloads.wordpress.org/plugin/redis-cache.latest-stable.zip
    # unzip redis-cache.latest-stable.zip
    # rm redis-cache.latest-stable.zip
    # chown -R www-data:www-data redis-cache

    # # Wait for Redis to be ready
    # echo "⏳ Waiting for Redis connection..."
    # timeout=30
    # while ! redis-cli -h redis ping >/dev/null 2>&1; do
    #     if [ "$timeout" -le 0 ]; then
    #         echo "❌ Redis connection timeout"
    #         exit 1
    #     fi
    #     sleep 1
    #     timeout=$((timeout-1))
    # done
    # echo "✅ Redis is ready"

	# Install WordPress if not present
    cd /var/www/wordpress || exit 1
    if [ ! -f "wp-config.php" ]; then
        wp core download --allow-root
        wp core config --dbhost=mariadb:3306 --dbname="$MYSQL_DB" --dbuser="$MYSQL_USER" --dbpass="$MYSQL_PASSWORD" --allow-root
    fi

	# Install and activate Redis plugin
    wp plugin install redis-cache --activate --allow-root --path=/var/www/wordpress

    # Configure Redis
    cat >> wp-config.php << EOF

/* Redis configuration */
define('WP_REDIS_DISABLE', false);
define('WP_REDIS_HOST', 'redis');
define('WP_REDIS_PORT', 6379);
define('WP_CACHE', true);
define('WP_REDIS_PREFIX', 'inception');
define('WP_REDIS_CLIENT', 'phpredis');
define('WP_REDIS_SCHEME', 'tcp');
define('WP_REDIS_DATABASE', 0);
define('WP_REDIS_CONNECTION_TIMEOUT', 5);
EOF

    # Wait for Redis
    echo "⏳ Waiting for Redis connection..."
    timeout=30
    while ! redis-cli -h redis ping >/dev/null 2>&1; do
        if [ "$timeout" -le 0 ]; then
            echo "❌ Redis connection timeout"
            exit 1
        fi
        sleep 1
        timeout=$((timeout-1))
    done
    echo "✅ Redis is ready"


    # # Add Redis config to wp-config.php (after DB constants)
    # sed -i '/\/\* That'\''s all, stop editing\! Happy publishing\. \*\//i\
    # require_once("wp-config-redis.php");' wp-config.php

	# Setup Redis cache
    wp redis update-dropin --allow-root --path=/var/www/wordpress
    chown www-data:www-data wp-content/object-cache.php
    wp redis enable --allow-root --path=/var/www/wordpress

    # Wait for cache to initialize
    sleep 2

    # Verify Redis connection
    cd /var/www/wordpress || exit 1
    if redis-cli -h redis ping | grep -q "PONG"; then
        echo "✅ Redis server responding"
        if wp redis status --allow-root --path=/var/www/wordpress 2>/dev/null | grep -q "Status: Connected"; then
            echo "✅ WordPress Redis cache enabled and connected"
        else
            echo "❌ WordPress Redis connection failed"
            wp redis status --allow-root --path=/var/www/wordpress || true
            exit 1
        fi
    else
        echo "❌ Redis server not responding"
        exit 1
    fi 
fi

# PHP-FPM configuration
sed -i '36 s@/run/php/php7.4-fpm.sock@9000@' /etc/php/7.4/fpm/pool.d/www.conf
mkdir -p /run/php

# Start PHP-FPM
exec /usr/sbin/php-fpm7.4 -F