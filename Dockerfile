FROM alpine:3.7

ENV COMPOSER_HOME /composer
ENV PATH $PATH:${COMPOSER_HOME}/vendor/bin
ENV PHPUNIT_VERSION 7.0.0

RUN apk update && apk add --no-cache \
    curl \
    git \
    php7 \
    php7-ctype \
    php7-dom \
    php7-iconv \
    php7-json \
    php7-mbstring \
    php7-openssl \
    php7-phar \
    php7-simplexml \
    php7-tokenizer \
    php7-xml \
    php7-xmlwriter \
    php7-zlib \
    && mkdir /composer \
    && curl --silent --show-error https://getcomposer.org/installer | php -- --install-dir=${COMPOSER_HOME} \
    && mv ${COMPOSER_HOME}/composer.phar /usr/local/bin/composer

WORKDIR /composer

RUN composer require drupal/coder \
    && phpcs --config-set installed_paths ${COMPOSER_HOME}/vendor/drupal/coder/coder_sniffer \
    && composer require phpmd/phpmd \
    && composer require phpunit/phpunit ^${PHPUNIT_VERSION}

WORKDIR /app

CMD ["phpcs", "--standard=Drupal,DrupalPractice", "."]
