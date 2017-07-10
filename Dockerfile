FROM php:7.1-apache
MAINTAINER Andre Marcelo-Tanner <andre@enthropia.com>

# Install specific packages
RUN apt-get update \
	&& DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    	apache2 \
    	mysql-client \
    	libjpeg-dev \
		libpng12-dev \
    	vim-tiny \
    	ca-certificates \
    	git-core \
    	ssh \
    ; \
    \
    docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr; \
	docker-php-ext-install gd mysqli opcache

# Disable apt-get
#RUN rm -rf /var/lib/apt/lists/*

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=2'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

# Fixes empty home
ENV HOME /root

# add custom ssh config / keys to the root user
ADD ./opt/docker/ssh/ /root/.ssh/

# Fixes permission if needed
# Avoid first connection host confirmation
RUN chmod 600 /root/.ssh/*; \
	ssh-keyscan -p22 github.com > /root/.ssh/known_hosts

# Change into the directory
WORKDIR /var/www/html

# Deploy local code into container
#ADD . /var/www/html
RUN git clone github.com/kzap/cryptocharts.git -o origin ./

# Configure

# Adding apache virtual hosts file
RUN cp ./opt/docker/apache-config/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf

# enable mods
RUN a2enmod rewrite expires

# Volume
VOLUME /var/www/html

# Run example docker run -it -p 8000:80 -e PHP_TIMEZONE='Asia/Manila' -v .:/var/www/html --name container-name