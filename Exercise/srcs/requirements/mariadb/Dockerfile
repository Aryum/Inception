FROM debian:bookworm

#installs mariadb removes unecessary files form updates
#removes default mariadb data
RUN apt-get update && apt-get install -y --no-install-recommends \
	mariadb-server \
	&& rm -rf /var/lib/mysql/* \
	&& rm -rf /var/lib/apt/lists/*

#makes folder structure and changes owner to mariadb user 
#user is created when installing mariadb
RUN mkdir -p /var/run/mysqld /var/log/mysql \
    && chown -R mysql:mysql /var/run/mysqld /var/log/mysql \
    && chmod 755 /var/run/mysqld /var/log/mysql

#overrides maria db default config with our config
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/

#contains initiation scripts for out database
COPY tools/init_db.sh /usr/local/bin

#sets permissions for the script file
RUN chmod +x /usr/local/bin/init_db.sh

#just tells the docker that it will listen from this port
#doesnt affect the image ports
EXPOSE 3306

ENTRYPOINT [ "/usr/local/bin/init_db.sh" ]

