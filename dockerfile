FROM php:7.4.12-fpm-alpine as base

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/bin/

RUN install-php-extensions gd mysqli intl pdo pdo_mysql bcmath zip sqlsrv pdo_sqlsrv calendar ssh2 mcrypt gmp
# Todo xdebug

# Chrome
RUN apk add chromium chromium-chromedriver git openssh-client gzip -y --no-cache

# Sql server necessary additions
RUN curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/msodbcsql17_17.5.1.1-1_amd64.apk \
    && curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/mssql-tools_17.5.1.2-1_amd64.apk \
    && apk add --allow-untrusted msodbcsql17_17.5.1.1-1_amd64.apk \
    && apk add --allow-untrusted mssql-tools_17.5.1.2-1_amd64.apk

ENV LC_ALL=C

#install composer globally
RUN curl -sSL https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer
ENV COMPOSER_ALLOW_SUPERUSER 1

ARG TYPE_ENV=production
RUN mv "$PHP_INI_DIR/php.ini-${TYPE_ENV}" "$PHP_INI_DIR/php.ini" \
    && sed -e 's/max_execution_time = 30/max_execution_time = 600/' -i "$PHP_INI_DIR/php.ini" \
    && sed -e 's/access.log = \/proc\/self\/fd\/2/access.log = \/dev\/null/' -i "/usr/local/etc/php-fpm.d/docker.conf"

ENV PHP_VERSION 7.4

# SQreen
RUN mkdir /tmp/sqreen-apk
ADD https://download.sqreen.com/php/sqreen-php-extension/alpine/sqreen-php-extension-latest-alpine.tar.gz /tmp/sqreen-apk
RUN cd /tmp/sqreen-apk && \
    tar -xzvf sqreen-php-extension-latest-alpine.tar.gz && \
    apk add --no-cache --allow-untrusted ${PHP_VERSION}/sq-ext-alpine-*.apk && \
    rm -r /tmp/sqreen-apk

COPY ./sqreen.ini /usr/local/etc/php/conf.d/90-sqreen.ini

RUN echo 'memory_limit = -1' > /usr/local/etc/php/conf.d/docker-php-memlimit.ini;

WORKDIR /var/www/html/

LABEL maintainer="joel@eurides.eu"