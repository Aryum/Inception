FROM debian:bookworm

RUN apt-get update && apt-get install -y \
	nginx \
	openssl \
	gettext-base \
	&& rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/nginx/ssl

COPY conf/nginx.conf /etc/template/nginx.conf.template
COPY tools/ini_ssl.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/ini_ssl.sh

ARG NGINX_PORT=443

EXPOSE ${NGINX_PORT}

ENTRYPOINT [ "/usr/local/bin/ini_ssl.sh" ]