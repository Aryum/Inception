FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
	php8.2-mysql \ 
	php8.2-mbstring \
	php8.2-fpm \
	php8.2-curl \
	php8.2-gd \
	php8.2-intl \
	php8.2-soap \
	php8.2-xml \
	php8.2-zip \
	ca-certificates \
	gettext-base \
	mariadb-client \
	wget \
	curl \
	&& ln -s /usr/sbin/php-fpm8.2 /usr/local/bin/php-fpm \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html

COPY conf/www.conf /etc/template/www.conf.template

COPY tools/ini_wp.sh /usr/local/bin/

RUN curl -fsSL -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/local/bin/wp

RUN chmod +x /usr/local/bin/ini_wp.sh

ARG WP_PORT=9000

EXPOSE ${WP_PORT}

ENTRYPOINT ["/usr/local/bin/ini_wp.sh"]