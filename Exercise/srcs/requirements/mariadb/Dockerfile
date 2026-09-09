FROM debian:bookworm

#installs mariadb removes unecessary files form updates
RUN apt-get update && apt-get install -y --no-install-recomends \
	mariadb-server \
	&& rm -rf /var/lib/apt/lists/*

#makes folder structure and changes owner to mariadb user 
#user is created when installing mariadb
RUN mkdir -p /var/run/mysqld \
	&& chown -R mysql:mysql /var/run/mysqld \
	&& chmod u=rwx,g=rx,o=rx /var/run/mysqld

#overrides maria db default config with our config
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/

#contains initiation scripts for out database
COPY tools/init_db.sh /usr/local/bin

#sets permissions for the script file
RUN chmod +x /usr/local/bin/init_db.sh

ENV MYSQL_ROOT_PASSWORD=root \
	MYSQL_USER=app_user \
	MYSQL_PASSWORD=app_pass

#just tells the docker that it will listen from this port
#doesnt affect the image ports
EXPOSE 3306