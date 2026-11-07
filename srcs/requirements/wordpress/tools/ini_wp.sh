#!/bin/bash
set -e

WP_PATH="/var/www/html"
SALT_FILE="$WP_PATH/SaltFile"
WP_DB_PASSWORD=$(cat "/run/secrets/db_wp_pass")
WP_ADMIN_PASSWORD=$(cat "/run/secrets/wp_admin_pass")
WP_BASIC_PASSWORD=$(cat "/run/secrets/wp_basic_pass")

TAR_FILE="$WP_PATH/wordpress.tar.gz"



echo "Initiating WordPress"

envsubst '${WP_PORT}' \
	< /etc/template/www.conf.template \
	> /etc/php/8.2/fpm/pool.d/www.conf


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
define('DB_PASSWORD', '${WP_DB_PASSWORD}');
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


echo "Waiting for MariaDB..."
connect_db() { mariadb-admin ping -h mariadb \
				-u"$WORDPRESS_DB_USER" -p"$WP_DB_PASSWORD" \
				--wait=30 --connect-timeout=3 --silent; }

if ! connect_db; then
	echo "Failed to connect to MariaDB"
	exit 1
fi
echo "MariaDB Ready"

wpcore_installed() { wp core is-installed --path="$WP_PATH" --allow-root 2>/dev/null; }
if ! wpcore_installed; then
	echo "Installing WordPress"
	wp core install \
		--path="$WP_PATH" \
		--url="https://${DOMAIN_NAME}" \
		--title="${WP_TITLE}" \
		--admin_user="${WP_ADMIN_USER}" \
		--admin_password="${WP_ADMIN_PASSWORD}" \
		--admin_email="${WP_ADMIN_USER}@email.com" \
		--skip-email \
		--allow-root
fi

wp option update blogname "${WP_TITLE}" --path="$WP_PATH" --allow-root

ensure_user()
{
	local login="$1" role="$2" pass="$3"
	if wp user get "$login" --path="$WP_PATH" --allow-root >/dev/null 2>&1; then
		wp user update "$login" \
			--user_email="$login@email.com" \
			--user_pass="$pass" \
			--role="$role" \
			--path="$WP_PATH" --allow-root
	else
		wp user create "$login" "$login@email.com" \
			--role="$role" \
			--user_pass="$pass" \
			--path="$WP_PATH" --allow-root
	fi

}

ensure_user "$WP_ADMIN_USER"  administrator "$WP_ADMIN_PASSWORD"
ensure_user "$WP_BASIC_USER"        author        "$WP_BASIC_PASSWORD"

echo "WordPress setup sucessful"

echo "Starting PHP-FPM"
exec php-fpm8.2 -F