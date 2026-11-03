#!/bin/bash
set -e

WP_PATH="/var/www/html"

passfile_set() { [ -n "$WORDPRESS_DB_PASSWORD_FILE" ]; }
passfile_exists() { [ -s "$WORDPRESS_DB_PASSWORD_FILE" ]; }

if passfile_set && passfile_exists; then
	WORDPRESS_DB_PASSWORD=$(cat "$WORDPRESS_DB_PASSWORD_FILE")
	export WORDPRESS_DB_PASSWORD
else
	echo "Password file not found or it's empty"
	exit 1
fi

echo "Initiating WordPress"

config_missing() { [ ! -f "$WP_PATH/wp-config.php" ]; }
if config_missing; then
	TAR_FILE="/tmp/wordpress.tar.gz"
	echo "Downloading files"
	wget -q https://wordpress.org/latest.tar.gz -O ${TAR_FILE}
	tar -xzf ${TAR_FILE} -C /tmp
	rm ${TAR_FILE}

	cp -rn /tmp/wordpress/* "$WP_PATH" || true
	rm -rf /tmp/wordpress
	
	WP_SALTS=$(wget -qO- https://api.wordpress.org/secret-key/1.1/salt/)

	cat > "$WP_PATH/wp-config.php" << EOF
<?php
define('WP_HOME', 'https://${DOMAIN_NAME}');
define('WP_SITEURL', 'https://${DOMAIN_NAME}');
define('DB_NAME', '${WORDPRESS_DB_NAME}');
define('DB_USER', '${MYSQL_WORDPRESS}');
define('DB_PASSWORD', '${WORDPRESS_DB_PASSWORD}');
define('DB_HOST', '${WORDPRESS_DB_HOST}');
define('DB_CHARSET', 'utf8mb4');


\$table_prefix = '${WORDPRESS_TABLE_PREFIX:-wp_}';

${WP_SALTS}

define('WP_DEBUG', false);

if ( !defined('ABSPATH') )
    define('ABSPATH', __DIR__ . '/');

require_once ABSPATH . 'wp-settings.php';
EOF
	find "$WP_PATH" -type d -exec chmod 750 {} \;
	find "$WP_PATH" -type f -exec chmod 640 {} \;
	chown -R www-data:www-data "$WP_PATH"

	echo "WordPress setup sucessful"
else
	echo "WordPress already initalized"
fi

echo "Starting PHP-FPM"
exec php-fpm8.2 -F