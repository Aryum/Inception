#!/bin/bash
set -e

WP_PATH="/var/www/html"
SALT_FILE="$WP_PATH/SaltFile"
DB_PASSWORD_FILE="/run/secrets/db_wp_pass"
TAR_FILE="$WP_PATH/wordpress.tar.gz"

echo "Initiating WordPress"

envsubst '${WP_PORT}' \
	< /etc/template/www.conf.template \
	> /etc/php/8.2/fpm/pool.d/www.conf


passfile_set() { [ -n "$DB_PASSWORD_FILE" ]; }
passfile_exists() { [ -s "$DB_PASSWORD_FILE" ]; }

if passfile_set && passfile_exists; then
	WORDPRESS_DB_PASSWORD=$(cat "$DB_PASSWORD_FILE")
	export WORDPRESS_DB_PASSWORD
else
	echo "Password file not found or it's empty"
	exit 1
fi

config_missing() { [ ! -s "$TAR_FILE" ]; }
if config_missing; then
	echo "Downloading files"
	wget -q https://wordpress.org/latest.tar.gz -O ${TAR_FILE}
	tar -xzf ${TAR_FILE} -C "$WP_PATH" --strip-components=1
	wget -qO- https://api.wordpress.org/secret-key/1.1/salt/ > "$SALT_FILE"
fi


cat > "$WP_PATH/wp-config.php" << EOF
<?php
define('WP_HOME', 'https://${DOMAIN_NAME}');
define('WP_SITEURL', 'https://${DOMAIN_NAME}');
define('DB_NAME', '${WORDPRESS_DB_NAME}');
define('DB_USER', '${WORDPRESS_DB_USER}');
define('DB_PASSWORD', '${WORDPRESS_DB_PASSWORD}');
define('DB_HOST', 'mariadb');
define('DB_CHARSET', 'utf8mb4');


\$table_prefix = 'wp_';

$(cat "$SALT_FILE")

define('WP_DEBUG', false);

if ( !defined('ABSPATH') )
    define('ABSPATH', __DIR__ . '/');

require_once ABSPATH . 'wp-settings.php';
EOF
find "$WP_PATH" -type d -exec chmod 750 {} \;
find "$WP_PATH" -type f -exec chmod 640 {} \;
chown -R www-data:www-data "$WP_PATH"

echo "WordPress setup sucessful"

echo "Starting PHP-FPM"
exec php-fpm8.2 -F