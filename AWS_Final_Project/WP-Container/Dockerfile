FROM wordpress:latest

# Inject HTTPS detection fix directly into the correct entrypoint
RUN { \
    echo "<?php"; \
    echo "if (isset(\$_SERVER['HTTP_X_FORWARDED_PROTO']) && strpos(\$_SERVER['HTTP_X_FORWARDED_PROTO'], 'https') !== false) {"; \
    echo "    \$_SERVER['HTTPS'] = 'on';"; \
    echo "    \$_SERVER['SERVER_PORT'] = 443;"; \
    echo "}"; \
    echo "define('FORCE_SSL_ADMIN', true);"; \
} > /usr/src/wordpress/wp-content/ssl-fix.php

# Override entrypoint to include custom fix
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

