#!/bin/bash
set -e

echo "Initiating MariaDB"

#Create MySQL data directory
#	--user specifies that user will be mysql
#	--datadir sets the correct location for the db so it is in the correct place
if [ ! -d "/var/lib/mysql/mysql" ]; then
	echo "	Creating data directory"
	mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null
fi

#stats the server skipping network since its not needed for startup
echo "	Starting MariaDB setup server"
mysql --skip-networking --socket=/run/mysqld/mysqld.sock --user=mysql & pid="$!"

if ! timeout 30s sh -c ' 
	until mysqladmin --socket=/run/mysqld/mysqld.sock ping
		sleep 1
	done '; 
then
	echo "	MariaDB startup Failed"
	exit 1
fi

echo "	MariaDB startup was successful"

#run setup sql to create database and users

