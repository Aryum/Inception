FROM debian:bookworm

RUN apt-get update && apt-get install -y \
	nginx \
	openssl \
	gettext-base \
	&& rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/nginx/ssl

COPY conf/nginx.conf /etc/nginx/nginx.conf.template
COPY tools/ini_ssl.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/ini_ssl.sh


RUN envsubst '${WP_PORT} ${DOMAIN_NAME}' \
	< /etc/nginx/nginx.conf.template \
	> /etc/nginx/nginx.conf

EXPOSE 443

ENTRYPOINT [ "/usr/local/bin/ini_ssl.sh" ]