#!/bin/bash
set -e

WP_PATH="/var/www/html"

#gets password form secret file
#checks if file exists and if has something
#export makes it available for child processes
passfile_exists() { [ -n "$WORDPRESS_DB_PASSWORD_FILE" ]; }
passfile_hascontent() { [ -f "$WORDPRESS_DB_PASSWORD_FILE" ]; }


if passfile_exists && passfile_hascontent; then
	WORDPRESS_DB_PASSWORD=$(cat "$WORDPRESS_DB_PASSWORD_FILE")
	export WORDPRESS_DB_PASSWORD
fi

echo "Initiating WordPress"


#download and configure wordpress if it wasnt done already
config_exists() { [ ! -f "$WP_PATH/wp-config.php" ] }
if config_exists; then
	TAR_FILE="/tmp/wordpress.tar.gz"
	echo "	Downloading files"
	wget -q https://wordpress.org/latest.tar.gz -O ${TAR_FILE}
	tar -xzf ${TAR_FILE} -C /tmp
	rm ${TAR_FILE}

	#copies without ovewriting things
	cp -rn /tmp/wordpress/* "$WP_PATH" || true
	rm -rf /tmp/wordpress
	
	#gets security salts from WP (salts is random data added to password for safer storing)
	#-q quiet to supress wget logs
	#-O- puts output in stdin so it can be stored in the var
	WP_SALTS=$(wget -qO- https://api.wordpress.org/secret-key/1.1/salt/)

	#creates config file
	#copies variables from env
	#	the \$ table_prefix is import so it does the literal $ and does not expand
	#	this just adds wp_ to the tables it creates it defaults to -wp_ if noting is set
	#	checks ABSPATH is set if not sets __DIR__ 
	#		that is a php var that means the current where the php file is being executed
	#	require_conce loads the php file if it wasnt loadded yet
	cat > "$WP_PATH/wp-config.php" << EOF
<?php
define('DB_NAME', '${WORDPRESS_DB_NAME}');
define('DB_USER', '${WORDPRESS_DB_USER}');
define('DB_PASSWORD', '${WORDPRESS_DB_PASSWORD}');
define('DB_HOST', '${WORDPRESS_DB_HOST}');
define('DB_CHARSET', 'utf8');
define('DB_COLLATE', '');


\$table_prefix = '${WORDPRESS_TABLE_PREFIX:-wp_}';

${WP_SALTS}

define('WP_DEBUG', false);

if ( !defined('ABSPATH') )
    define('ABSPATH', __DIR__ . '/');

require_once ABSPATH . 'wp-settings.php';
EOF
	#sets permissions and ownership of WP files and directories
	#	Directories owner has permission to rwx group only r-x
	#	Files owner has permission to rw- group only r--
	#	changes the ownwer and group of the files
	find "$WP_PATH" -type d -exec chmod 750 {} \;
	find "$WP_PATH" -type f -exec chmod 640 {} \;
	chown -R www-data:www-data "$WP_PATH"

	echo "	WordPress setup sucessful"
else
	echo "	WordPress already initalized"
fi

echo "Starting PHP-FPM"
#starts php manager 
#	-F makes it run on the foreground
#	exec replaces the process becoming the main process of the container
#		thus our manager will recieve all the signals and things like that
exec php-fpm8.2 -F