FROM debian:bookworm

#installs PHP-FPM and extensions needed
#php8.2-mysql -> for database connection
#php8.2-mbstring -> to be able to handle multibyte chars
#php8.2-fpm -> allows conncection to nginx
#php8.2-gd -> image resizing
#php8.2-zip -> install plugins and themes
#php8.2-curl -> for core/plugin/theme updates
#php8.2-xml -> used to process XML data
#php8.2-intl -> for local aware formating
#php8.2-soap -> integration of some plugins
#certificates to be able to download with wget
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
	wget \
	curl \
	&& ln -s /usr/sbin/php-fpm8.2 /usr/local/bin/php-fpm \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html

COPY conf/www.conf /etc/php/8.2/fpm/pool.d/

COPY tools/ini_wp.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/ini_wp.sh

EXPOSE 9000

#makes it so the sh is always run at container startup
ENTRYPOINT ["/usr/local/bin/ini_wp.sh"]