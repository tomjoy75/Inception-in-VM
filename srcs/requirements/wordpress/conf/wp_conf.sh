#!/bin/bash

# Enable error reporting but don't exit on error
set -e

# Configure PHP-FPM pool settings
cat > /etc/php/7.4/fpm/pool.d/www.conf << EOL
[www]
user = www-data
group = www-data
listen = 9000
pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
clear_env = no

; Additional settings
php_admin_value[error_log] = /var/log/php7.4-fpm.log
php_admin_flag[log_errors] = on
php_admin_value[memory_limit] = 256M
EOL

# Create necessary directories with proper permissions
mkdir -p /run/php /var/log
touch /var/log/php7.4-fpm.log
chown -R www-data:www-data /run/php /var/log/php7.4-fpm.log

# Initialize WordPress directory
cd /var/www/wordpress

# Download WordPress only if not already present
if [ ! -f "wp-config.php" ]; then
    wp core download --allow-root
    wp core config --dbhost=mariadb:3306 --dbname="$MYSQL_DB" --dbuser="$MYSQL_USER" --dbpass="$MYSQL_PASSWORD" --allow-root
    wp core install --url="$DOMAIN_NAME" --title="$WP_TITLE" --admin_user="$WP_ADMIN_N" --admin_password="$WP_ADMIN_P" --admin_email="$WP_ADMIN_E" --allow-root
    wp user create "$WP_U_NAME" "$WP_U_EMAIL" --user_pass="$WP_U_PASS" --role="$WP_U_ROLE" --allow-root
fi

# Redis configuration
if [ "$ENABLE_BONUS" = "true" ]; then
    echo "🔄 Setting up Redis..."
    
    # Wait for Redis setup
    max_tries=30
    while [ $max_tries -gt 0 ]; do
        if redis-cli -h redis ping > /dev/null 2>&1; then
            echo "✅ Redis is ready"
            break
        fi
        max_tries=$((max_tries-1))
        echo "⏳ Waiting for Redis... ($max_tries tries left)"
        sleep 1
    done

    if [ $max_tries -gt 0 ]; then
        wp plugin install redis-cache --activate --allow-root || true
        wp config set WP_REDIS_HOST redis --allow-root
        wp config set WP_REDIS_PORT 6379 --allow-root
        wp config set WP_CACHE true --allow-root
        wp config set WP_REDIS_PREFIX inception --allow-root
        wp config set WP_REDIS_CLIENT phpredis --allow-root
        wp config set WP_REDIS_SCHEME tcp --allow-root
        wp config set WP_REDIS_TIMEOUT 1 --allow-root
        wp config set WP_REDIS_READ_TIMEOUT 1 --allow-root
        wp redis enable --allow-root || true
        echo "✅ Redis configuration completed"
    else
        echo "⚠️ Redis not available, continuing without cache"
    fi
else
    # If Redis is not enabled, make sure it's properly disabled
    wp plugin deactivate redis-cache --allow-root 2>/dev/null || true
    wp plugin uninstall redis-cache --allow-root 2>/dev/null || true
    wp config delete WP_REDIS_HOST --allow-root 2>/dev/null || true
    wp config delete WP_CACHE --allow-root 2>/dev/null || true
fi

# Start PHP-FPM in foreground
exec php-fpm7.4 -F