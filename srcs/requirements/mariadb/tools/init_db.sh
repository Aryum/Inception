#!/bin/bash
set -e

DB_DIR="/var/lib/mysql"
SOCKET="/run/mysqld/mysqld.sock"
WORDPRESS_DB_PASSWORD="$(cat /run/secrets/db_wp_pass)"
ROOT_DB_PASSWORD="$(cat /run/secrets/db_root_pass)"

echo "Initiating MariaDB"

envsubst '${MYSQL_PORT}' \
	< /etc/template/50-server.cnf.template \
	> /etc/mysql/mariadb.conf.d/50-server.cnf


database_missing() { [ ! -d "${DB_DIR}/mysql" ]; }

if database_missing; then
	echo "Creating database directory"
	mysql_install_db --user=mysql --datadir="${DB_DIR}" > /dev/null
fi

echo "Starting MariaDB setup server"
mysqld --skip-networking --skip-grant-tables --socket="${SOCKET}" --user=mysql & pid="$!"

if ! mysqladmin --socket="${SOCKET}" ping --silent --wait=30 --connect-timeout=3; then
	echo "  MariaDB startup Failed"
	exit 1
fi

echo "MariaDB startup was successful"

echo "Setting up SQl"
mysql --socket=${SOCKET} -u root << EOF
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_DB_PASSWORD}';
CREATE DATABASE IF NOT EXISTS ${WORDPRESS_DB_NAME};
CREATE OR REPLACE USER '${WORDPRESS_DB_USER}'@'%' IDENTIFIED BY '${WORDPRESS_DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${WORDPRESS_DB_NAME}.* TO '${WORDPRESS_DB_USER}'@'%';
FLUSH PRIVILEGES;
EOF

echo "Shutting down setup server "
timeout 30 env MYSQL_PWD="${ROOT_DB_PASSWORD}" mysqladmin --socket="${SOCKET}" -u root shutdown
wait "$pid" || true

echo "Starting database"
exec mysqld --user=mysql --datadir="${DB_DIR}" --socket="${SOCKET}"