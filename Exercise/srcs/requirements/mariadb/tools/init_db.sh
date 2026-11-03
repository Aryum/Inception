#!/bin/bash
set -e

DB_DIR="/var/lib/mysql"
SOCKET="/run/mysqld/mysqld.sock"
MYSQL_ADMIN_PASSWORD="$(cat "$MYSQL_ADMIN_PASSWORD_FILE")"
MYSQL_USER_PASSWORD="$(cat "$MYSQL_USER_PASSWORD_FILE")"
MYSQL_WP_PASSWORD="$(cat "$MYSQL_WP_PASSWORD_FILE")"
MYSQL_ROOT_PASSWORD="$(cat "$MYSQL_ROOT_PASSWORD_FILE")"

echo "Initiating MariaDB"

database_missing() { [ ! -d "${DB_DIR}/${MYSQL_DATABASE}" ]; }

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
DELETE FROM mysql.global_priv WHERE User = '';
DELETE FROM mysql.db WHERE User = '';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE OR REPLACE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_USER_PASSWORD}';
GRANT SELECT ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
CREATE OR REPLACE USER '${MYSQL_ADMIN}'@'%' IDENTIFIED BY '${MYSQL_ADMIN_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_ADMIN}'@'%';
CREATE OR REPLACE USER '${MYSQL_WORDPRESS}'@'%' IDENTIFIED BY '${MYSQL_WP_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_WORDPRESS}'@'%';
FLUSH PRIVILEGES;
EOF

echo "Shutting down setup server "
timeout 30 env MYSQL_PWD="${MYSQL_ROOT_PASSWORD}" mysqladmin --socket="${SOCKET}" -u root shutdown
wait "$pid" || true

echo "Starting database"
exec mysqld --user=mysql --datadir="${DB_DIR}" --socket="${SOCKET}"