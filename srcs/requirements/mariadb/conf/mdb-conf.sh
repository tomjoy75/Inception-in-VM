#!/bin/bash

# Create required directories
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld /var/lib/mysql

# Initialize MariaDB data directory if needed
if [ ! -d "/var/lib/mysql/mysql" ]; then
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
fi

# Start MariaDB service
service mariadb start

# Wait for MariaDB to be ready
until mysqladmin ping >/dev/null 2>&1; do
    echo -n "."
    sleep 1
done

# Set root password and create database
mariadb -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';"
mariadb -u root -p${MYSQL_ROOT_PASSWORD} -e "CREATE DATABASE IF NOT EXISTS \`${MYSQL_DB}\`;"
mariadb -u root -p${MYSQL_ROOT_PASSWORD} -e "CREATE USER IF NOT EXISTS \`${MYSQL_USER}\`@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';"
mariadb -u root -p${MYSQL_ROOT_PASSWORD} -e "GRANT ALL PRIVILEGES ON ${MYSQL_DB}.* TO \`${MYSQL_USER}\`@'%';"
mariadb -u root -p${MYSQL_ROOT_PASSWORD} -e "FLUSH PRIVILEGES;"

# Restart MariaDB with proper configuration
mysqladmin -u root -p${MYSQL_ROOT_PASSWORD} shutdown

exec mysqld_safe --user=mysql --port=3306 --bind-address=0.0.0.0 --datadir=/var/lib/mysql