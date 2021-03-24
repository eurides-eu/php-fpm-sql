FROM php:8.0.3-fpm-alpine3.12 as base

COPY --from=mlocati/php-extension-installer:1.2.23 /usr/bin/install-php-extensions /usr/bin/

# Sqlserver drivers: https://docs.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server?view=sql-server-ver15#alpine17
RUN curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/msodbcsql17_17.7.2.1-1_amd64.apk \
    && curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/mssql-tools_17.7.1.1-1_amd64.apk \
    && apk add --allow-untrusted msodbcsql17_17.7.2.1-1_amd64.apk mssql-tools_17.7.1.1-1_amd64.apk
ENV LC_ALL=C

# RUN add php extensions
RUN install-php-extensions gd mysqli intl pdo pdo_mysql bcmath zip pdo_sqlsrv calendar ssh2 mcrypt gmp sqlsrv-5.9.0
# Todo xdebug

# Chrome
RUN apk add chromium chromium-chromedriver git openssh-client gzip -y --no-cache

#install composer globally
RUN curl -sSL https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer
ENV COMPOSER_ALLOW_SUPERUSER 1

ARG TYPE_ENV=production
RUN mv "$PHP_INI_DIR/php.ini-${TYPE_ENV}" "$PHP_INI_DIR/php.ini" \
    && sed -e 's/max_execution_time = 30/max_execution_time = 600/' -i "$PHP_INI_DIR/php.ini" \
    && sed -e 's/access.log = \/proc\/self\/fd\/2/access.log = \/dev\/null/' -i "/usr/local/etc/php-fpm.d/docker.conf"

ENV PHP_VERSION 8.0

# SQreen
RUN mkdir /tmp/sqreen-apk
ADD https://download.sqreen.com/php/sqreen-php-extension/alpine/sqreen-php-extension-latest-alpine.tar.gz /tmp/sqreen-apk
RUN cd /tmp/sqreen-apk && \
    tar -xzvf sqreen-php-extension-latest-alpine.tar.gz && \
    apk add --no-cache --allow-untrusted ${PHP_VERSION}/sq-ext-alpine-*.apk && \
    rm -r /tmp/sqreen-apk

RUN apk add datadog-php-tracer_0.56.0_noarch.apk --allow-untrusted

COPY ./sqreen.ini /usr/local/etc/php/conf.d/90-sqreen.ini

RUN echo 'memory_limit = -1' > /usr/local/etc/php/conf.d/docker-php-memlimit.ini;

WORKDIR /var/www/html/

LABEL maintainer="joel@eurides.eu"