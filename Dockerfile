FROM php:8.2.7-fpm
LABEL maintainer="PraserX <praserx@gmail.com>"
LABEL description="Unofficial up-to-date Dockerfile for Grav based on \
    offical docker-grav"

# Install dependencies
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    nginx \
    unzip \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libyaml-dev \
    libzip4 \
    libzip-dev \
    zlib1g-dev \
    libicu-dev \
    g++ \
    git \
    cron \
    vim \
    procps \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install \
    opcache \
    zip \
    && docker-php-ext-configure intl \
    && docker-php-ext-install intl \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd

# Install PHP extensions via PECL
RUN pecl channel-update pecl.php.net \
    && pecl install apcu yaml \ 
    && docker-php-ext-enable apcu yaml

RUN rm -rf /usr/local/etc/php-fpm.d/zz-docker.conf

# Configure nginx - http
COPY config/nginx.conf /etc/nginx/nginx.conf
# Configure nginx - default server
COPY config/conf.d /etc/nginx/conf.d/

# Configure PHP-FPM
COPY config/fpm-pool.conf /usr/local/etc/php-fpm.d/www.conf
COPY config/php.ini /usr/local/etc/php/conf.d/custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=2'; \
    echo 'opcache.fast_shutdown=1'; \
    echo 'opcache.enable_cli=1'; \
    echo 'upload_max_filesize=128M'; \
    echo 'post_max_size=128M'; \
    echo 'expose_php=off'; \
    } > /usr/local/etc/php/conf.d/php-recommended.ini

# Set user to www-data
RUN chown www-data:www-data /var/www
USER www-data

# Define Grav specific version of Grav or use latest stable
ARG GRAV_VERSION=1.7.41.2

# Install Grav (with admin extension)
WORKDIR /var/www
RUN curl -o grav-admin.zip -SL https://getgrav.org/download/core/grav-admin/${GRAV_VERSION} && \
    unzip grav-admin.zip && \
    rm -rf /var/www/html && \
    mv -T /var/www/grav-admin /var/www/html && \
    rm grav-admin.zip

# Install additional modules
RUN cd /var/www/html && bin/gpm install simplesearch breadcrumbs auto-date

# Create cron job for Grav maintenance scripts
RUN (crontab -l; echo "* * * * * cd /var/www/html;/usr/local/bin/php bin/grav scheduler 1>> /dev/null 2>&1") | crontab 

# provide container inside image for data persistence
VOLUME ["/var/www/html"]

USER root

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping















# # Enable Apache Rewrite + Expires Module
# RUN a2enmod rewrite expires && \
#     sed -i 's/ServerTokens OS/ServerTokens ProductOnly/g' \
#     /etc/apache2/conf-available/security.conf

# # Install dependencies
# RUN apt-get update && apt-get install -y --no-install-recommends \
#     unzip \
#     libfreetype6-dev \
#     libjpeg62-turbo-dev \
#     libpng-dev \
#     libyaml-dev \
#     libzip4 \
#     libzip-dev \
#     zlib1g-dev \
#     libicu-dev \
#     g++ \
#     git \
#     cron \
#     vim \
#     && rm -rf /var/lib/apt/lists/*

# # Install PHP extensions
# RUN docker-php-ext-install \
#     opcache \
#     zip \
#     && docker-php-ext-configure intl \
#     && docker-php-ext-install intl \
#     && docker-php-ext-configure gd --with-freetype --with-jpeg \
#     && docker-php-ext-install -j$(nproc) gd

# # Install PHP extensions via PECL
# RUN pecl channel-update pecl.php.net \
#     && pecl install apcu yaml \ 
#     && docker-php-ext-enable apcu yaml

# # set recommended PHP.ini settings
# # see https://secure.php.net/manual/en/opcache.installation.php
# RUN { \
#     echo 'opcache.memory_consumption=128'; \
#     echo 'opcache.interned_strings_buffer=8'; \
#     echo 'opcache.max_accelerated_files=4000'; \
#     echo 'opcache.revalidate_freq=2'; \
#     echo 'opcache.fast_shutdown=1'; \
#     echo 'opcache.enable_cli=1'; \
#     echo 'upload_max_filesize=128M'; \
#     echo 'post_max_size=128M'; \
#     echo 'expose_php=off'; \
#     } > /usr/local/etc/php/conf.d/php-recommended.ini

# # Set user to www-data
# RUN chown www-data:www-data /var/www
# USER www-data

# # Define Grav specific version of Grav or use latest stable
# ARG GRAV_VERSION=1.7.41.1

# # Install Grav (with admin extension)
# WORKDIR /var/www
# RUN curl -o grav-admin.zip -SL https://getgrav.org/download/core/grav-admin/${GRAV_VERSION} && \
#     unzip grav-admin.zip && \
#     mv -T /var/www/grav-admin /var/www/html && \
#     rm grav-admin.zip

# # Install additional modules
# RUN cd /var/www/html && bin/gpm install simplesearch breadcrumbs auto-date

# # Create cron job for Grav maintenance scripts
# RUN (crontab -l; echo "* * * * * cd /var/www/html;/usr/local/bin/php bin/grav scheduler 1>> /dev/null 2>&1") | crontab -

# # Return to root user
# USER root

# # Copy init scripts
# # COPY docker-entrypoint.sh /entrypoint.sh

# # provide container inside image for data persistence
# VOLUME ["/var/www/html"]

# # ENTRYPOINT ["/entrypoint.sh"]
# # CMD ["apache2-foreground"]
# CMD ["sh", "-c", "cron && apache2-foreground"]