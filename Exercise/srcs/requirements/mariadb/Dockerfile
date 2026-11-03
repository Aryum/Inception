FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
	mariadb-server \
	&& rm -rf /var/lib/mysql/* \
	&& rm -rf /var/lib/apt/lists/*

	RUN mkdir -p /var/run/mysqld /var/log/mysql \
    && chown -R mysql:mysql /var/run/mysqld /var/log/mysql \
    && chmod 755 /var/run/mysqld /var/log/mysql

COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/

COPY tools/init_db.sh /usr/local/bin

RUN chmod +x /usr/local/bin/init_db.sh

EXPOSE 3306

ENTRYPOINT [ "/usr/local/bin/init_db.sh" ]

