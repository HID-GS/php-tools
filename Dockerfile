FROM alpine:3.7

ENV WORKING_DIR /usr/local/share
ENV PATH $PATH:${WORKING_DIR}/vendor/bin
ENV PHPUNIT_VERSION 7.0.0
ENV DRUSH_VERSION 8.0.0
ENV TERMINUS_PLUGINS_DIR ${WORKING_DIR}/.terminus/plugins
ENV TERMINUS_CACHE_DIR ${WORKING_DIR}/.terminus/cache

RUN apk update && apk add --no-cache \
    curl \
    git \
    openssh-client \
    php7 \
    php7-ctype \
    php7-curl \
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
    && curl --silent --show-error https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

COPY ./build-tools-ci.sh /scripts/

WORKDIR ${WORKING_DIR}

# Add symfony/yaml ^3.4.0 to resolve conflict in terminus
RUN mkdir -p ${TERMINUS_PLUGINS_DIR} ${TERMINUS_CACHE_DIR} \
    && composer -n require symfony/yaml ^3.4.0 \
    && composer -n require drupal/coder \
    && phpcs --config-set installed_paths ${WORKING_DIR}/vendor/drupal/coder/coder_sniffer \
    && composer -n require phpmd/phpmd \
    && composer -n require drush/drush ^${DRUSH_VERSION} \
    && composer -n require phpunit/phpunit ^${PHPUNIT_VERSION} \
    && composer -n require pantheon-systems/terminus \
    && composer create-project -n -d ${TERMINUS_PLUGINS_DIR} pantheon-systems/terminus-build-tools-plugin:~1 \
    && chmod +x /scripts/build-tools-ci.sh

WORKDIR /app

CMD ["phpcs", "--standard=Drupal,DrupalPractice", "."]
