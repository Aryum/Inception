FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
	mariadb-server \
	gettext-base \
	&& rm -rf /var/lib/mysql/* \
	&& rm -rf /var/lib/apt/lists/*

	RUN mkdir -p /var/run/mysqld /var/log/mysql \
    && chown -R mysql:mysql /var/run/mysqld /var/log/mysql \
    && chmod 755 /var/run/mysqld /var/log/mysql

COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf.template

COPY tools/init_db.sh /usr/local/bin

RUN chmod +x /usr/local/bin/init_db.sh

RUN envsubst '${MYSQL_PORT}' \
	< /etc/mysql/mariadb.conf.d/50-server.cnf.template \
	> /etc/mysql/mariadb.conf.d/50-server.cnf

EXPOSE 3306

ENTRYPOINT [ "/usr/local/bin/init_db.sh" ]

