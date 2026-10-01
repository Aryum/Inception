#!/bin/bash
#if anything fails it kills the script
set -e

DB_DIR="/var/lib/mysql"
SOCKET="/run/mysqld/mysqld.sock"
MYSQL_ADMIN_PASSWORD="$(cat "$MYSQL_ADMIN_PASSWORD_FILE")"
MYSQL_USER_PASSWORD="$(cat "$MYSQL_USER_PASSWORD_FILE")"
MYSQL_WP_PASSWORD="$(cat "$MYSQL_WP_PASSWORD_FILE")"
MYSQL_ROOT_PASSWORD="$(cat "$MYSQL_ROOT_PASSWORD_FILE")"



echo "Initiating MariaDB"

#Create MySQL data directory
#	--user specifies that user will be mysql
#	--datadir sets the correct location for the db so it is in the correct place
database_missing() { [ ! -d "${DB_DIR}/${MYSQL_DATABASE}" ]; }

if database_missing; then
	echo "Creating database directory"
	mysql_install_db --user=mysql --datadir="${DB_DIR}" > /dev/null
else

#stats the server skipping network since its not needed for startup
#the mysqld is diferent from mysql the "d" is for the server without the "d" is client
echo "Starting MariaDB setup server"
mysqld --skip-networking --socket="${SOCKET}" --user=mysql & pid="$!"

#waits for 30 secs and tries a new conncetion after 3 secs if one is hanging
if ! mysqladmin --socket="${SOCKET}" ping --silent --wait=30 --connect-timeout=3; then
	echo "  MariaDB startup Failed"
	exit 1
fi

echo "MariaDB startup was successful"

echo "Setting up SQl"
#run setup sql to create database and users
#connects to database server as root using the socket we created
#since its 1st setup it doesnt have a password yet and we dont need -p
# '%' is the host wildcard that allows connection from any ip, can be restrained
# flush privileges reloads the permissions tables to the changes take place immediately
mysql --socket=/run/mysqld/mysqld.sock -u root << EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE OR REPLACE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_USER_PASSWORD}';
GRANT SELECT ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
CREATE OR REPLACE USER '${MYSQL_ADMIN}'@'%' IDENTIFIED BY '${MYSQL_ADMIN_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_ADMIN}'@'%';
CREATE OR REPLACE USER '${MYSQL_WORDPRESS}'@'%' IDENTIFIED BY '${MYSQL_WP_PASSWORD}';
GRANT SELECT, INSERT, UPDATE, DELETE ON ${MYSQL_DATABASE}.* TO '${MYSQL_WORDPRESS}'@'%';
FLUSH PRIVILEGES;
EOF
#waits for the shutdown of setup server
#the wait || true serves to wait until the shutdown actually finishes and 
#|| true is so it disregards the return of the server and the sh doesnt fail through set -e
echo "Shutting down setup server "
timeout 30 env MYSQL_PWD="${MYSQL_ROOT_PASSWORD}" mysqladmin --socket="${SOCKET}" -u root shutdown
wait "$pid" || true

echo "Starting database"
exec mysqld --user=mysql --datadir="${DB_DIR}" --socket="${SOCKET}"