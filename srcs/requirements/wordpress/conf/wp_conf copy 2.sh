#!/bin/bash
#---------------------------------------------------wp installation---------------------------------------------------#
# wp-cli installation
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
# wp-cli permission
chmod +x wp-cli.phar
# wp-cli move to bin
mv wp-cli.phar /usr/local/bin/wp

# go to wordpress directory
cd /var/www/wordpress
# give permission to wordpress directory
chmod -R 755 /var/www/wordpress/
# change owner of wordpress directory to www-data
chown -R www-data:www-data /var/www/wordpress
#---------------------------------------------------wp installation---------------------------------------------------##---------------------------------------------------wp installation---------------------------------------------------#

# download wordpress core files
wp core download --allow-root

# create wp-config.php file with database details
wp core config --dbhost=mariadb:3306 --dbname="$MYSQL_DB" --dbuser="$MYSQL_USER" --dbpass="$MYSQL_PASSWORD" --allow-root

# Redis configuration for bonus - MOVED BEFORE wp-config.php creation
if [ "$ENABLE_BONUS" = "true" ]; then
    echo "🔄 Configuring Redis cache..."
    
    # Download Redis plugin manually for better control
    cd /var/www/wordpress/wp-content/plugins/
    curl -LO https://downloads.wordpress.org/plugin/redis-cache.latest-stable.zip
    unzip redis-cache.latest-stable.zip
    rm redis-cache.latest-stable.zip
    chown -R www-data:www-data redis-cache
    cd /var/www/wordpress
    
	# # Wait for Redis to be ready
    # echo "⏳ Waiting for Redis..."
    # timeout=30
    # while ! redis-cli -h redis ping >/dev/null 2>&1; do
    #     if [ "$timeout" -le 0 ]; then
    #         echo "❌ Redis connection timeout"
    #         exit 1
    #     fi
    #     sleep 1
    #     timeout=$((timeout-1))
    # done
    
    # Create Redis configuration file
    cat > /tmp/redis-config.php << EOF
define('WP_REDIS_HOST', 'redis');
define('WP_REDIS_PORT', 6379);
define('WP_CACHE', true);
define('WP_REDIS_PREFIX', 'inception');
define('WP_REDIS_CLIENT', 'phpredis');
define('WP_REDIS_SCHEME', 'tcp');
define('WP_REDIS_DATABASE', 0);
define('WP_REDIS_CONNECTION_TIMEOUT', 5);
EOF
	# Add Redis configuration to wp-config.php
    sed -i '/\/\* That'\''s all, stop editing\! Happy publishing\. \*\//i\
    require_once("/tmp/redis-config.php");' /var/www/wordpress/wp-config.php
fi	
#     # Download and install Redis plugin
#     wp plugin install redis-cache --allow-root
    
#     # Prepare Redis configuration
#     echo "define('WP_REDIS_HOST', 'redis');" >> /tmp/redis-config.php
#     echo "define('WP_REDIS_PORT', 6379);" >> /tmp/redis-config.php
#     echo "define('WP_CACHE', true);" >> /tmp/redis-config.php
#     echo "define('WP_REDIS_PREFIX', 'inception');" >> /tmp/redis-config.php
# fi

# install wordpress with the given title, admin username, password and email
wp core install --url="$DOMAIN_NAME" --title="$WP_TITLE" --admin_user="$WP_ADMIN_N" --admin_password="$WP_ADMIN_P" --admin_email="$WP_ADMIN_E" --allow-root
#create a new user with the given username, email, password and role
wp user create "$WP_U_NAME" "$WP_U_EMAIL" --user_pass="$WP_U_PASS" --role="$WP_U_ROLE" --allow-root

# Activate Redis plugin after WordPress installation
if [ "$ENABLE_BONUS" = "true" ]; then
    echo "🔄 Activating Redis plugin..."
    # Remove existing object cache if present
    rm -f /var/www/wordpress/wp-content/object-cache.php

	# # Wait for Redis before activating plugin
    # echo "⏳ Waiting for Redis..."
    # timeout=30
    # while ! redis-cli -h redis ping >/dev/null 2>&1; do
    #     if [ "$timeout" -le 0 ]; then
    #         echo "❌ Redis connection timeout"
    #         exit 1
    #     fi
    #     sleep 1
    #     timeout=$((timeout-1))
    # done
    
    # Enable Redis cache
    wp plugin activate redis-cache --allow-root
	wp redis update-dropin --allow-root
	chown www-data:www-data /var/www/wordpress/wp-content/object-cache.php
    wp redis enable --allow-root

	# Verify Redis status
    echo "🔍 Checking Redis status..."
    sleep 2  # Give Redis a moment to connect
	    if wp redis status --allow-root | grep -q "Status: Connected"; then
        echo "✅ Redis cache enabled and connected"
    else
        echo "❌ Redis connection verification failed"
        wp redis status --allow-root
        exit 1
    fi
fi
#---------------------------------------------------php config---------------------------------------------------#

# change listen port from unix socket to 9000
sed -i '36 s@/run/php/php7.4-fpm.sock@9000@' /etc/php/7.4/fpm/pool.d/www.conf
# create a directory for php-fpm
mkdir -p /run/php
# start php-fpm service in the foreground to keep the container running
exec /usr/sbin/php-fpm7.4 -F


