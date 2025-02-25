#!/bin/bash
#set -e

# if [ "$ENABLE_BONUS" = "true" ]; then
#     echo "Enabling Adminer configuration..."
#     mv /etc/nginx/conf.d/adminer.conf.disabled /etc/nginx/conf.d/adminer.conf
# fi

# exec "$@"

# # Debug output
# echo "ENABLE_BONUS value: $ENABLE_BONUS"
# echo "Checking Nginx configuration files:"
# ls -la /etc/nginx/conf.d/

# if [ "$ENABLE_BONUS" = "true" ]; then
#     echo "Enabling Adminer configuration..."
#     if [ -f "/etc/nginx/conf.d/adminer.conf.disabled" ]; then
#         mv /etc/nginx/conf.d/adminer.conf.disabled /etc/nginx/conf.d/adminer.conf
#         echo "Adminer configuration enabled successfully"
#         nginx -t
#     else
#         echo "Warning: adminer.conf.disabled not found!"
#         ls -la /etc/nginx/conf.d/
#     fi
# fi

# exec "$@"
#!/bin/bash
set -e

echo "ENABLE_BONUS value: $ENABLE_BONUS"

# Create empty config directory if it doesn't exist
mkdir -p /etc/nginx/conf.d

if [ "$ENABLE_BONUS" = "true" ]; then
    echo "Enabling Adminer configuration..."
    if [ -f "/etc/nginx/conf.d/adminer.conf.disabled" ]; then
        mv /etc/nginx/conf.d/adminer.conf.disabled /etc/nginx/conf.d/adminer.conf
        echo "Adminer configuration enabled"
    else
        echo "Warning: adminer.conf.disabled not found"
    fi
else
    echo "Running without bonus features"
    rm -f /etc/nginx/conf.d/*.conf
fi

# Test nginx configuration
nginx -t

exec "$@"