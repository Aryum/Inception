FROM debian:bookworm

RUN apt-get update && apt-get install -y \
	nginx \
	openssl \
	&& rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/nginx/ssl

COPY conf/nginx.conf /etc/nginx/nginx.conf.template
COPY tools/ini_ssl.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/ini_ssl.sh

EXPOSE 443

ENTRYPOINT [ "/usr/local/bin/ini_ssl.sh" ]