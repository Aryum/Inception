FROM debian:bookworm

RUN apt-get update && apt-get install -y \
	nginx \
	openssl \
	&& rm -rf /var/lib/apt/lists/*

#might need to change user id and/or group if errors come up
#RUN usermod -u 33 www-data && groupmod -g 33 www-data


RUN mkdir -p /etc/nginx/ssl

COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY tools/ini_ssl.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/ini_ssl.sh

EXPOSE 443

ENTRYPOINT [ "/usr/local/bin/ini_ssl.sh" ]