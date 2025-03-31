#!/bin/bash
set -euo pipefail

# First run original WordPress entrypoint
docker-entrypoint.sh apache2-foreground &

# Wait briefly to ensure wp-config.php exists
sleep 10

# Inject fix if wp-config.php exists and doesn't already contain the fix
if [ -f "/var/www/html/wp-config.php" ] && ! grep -q "HTTP_X_FORWARDED_PROTO" /var/www/html/wp-config.php; then
    cat /usr/src/wordpress/wp-content/ssl-fix.php >> /var/www/html/wp-config.php
fi

wait

