#!/bin/bash
#if anything fails it kills the script
DB_DIR="/var/lib/mysql"
SOCKET="/run/mysqld/mysqld.sock"

set -e

echo "Initiating MariaDB"

#Create MySQL data directory
#	--user specifies that user will be mysql
#	--datadir sets the correct location for the db so it is in the correct place
database_missing() { [ ! -d "${DB_DIR}/mysql" ]; }

if database_missing; then
	echo "	Creating data directory"
	mysql_install_db --user=mysql --datadir=${DB_DIR} > /dev/null
fi

#stats the server skipping network since its not needed for startup
#the mysqld is diferent from mysql the "d" is for the server without the "d" is client
echo "	Starting MariaDB setup server"
mysqld --skip-networking --socket=${SOCKET} --user=mysql & pid="$!"

#waits for 30 secs and tries a new conncetion after 3 secs if one is hanging
if ! mysqladmin --socket="${SOCKET}" ping --silent --wait=30 --connect-timeout=3; then
    echo "  MariaDB startup Failed"
    exit 1
fi

echo "	MariaDB startup was successful"

#run setup sql to create database and users

echo "	Setting up SQl"
#connects to database server as root using the socket we created
#since its 1st setup it doesnt have a password yet and we dont need -p
# '%' is the host wildcard that allows connection from any ip, can be restrained
# flush privileges reloads the permissions tables to the changes take place immediately

mysql --socket=/run/mysqld/mysqld.sock -u root << EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

echo "	Shutting down setup server "
mysqladmin --socket=${SOCKET} -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown

wait "$pid" || true