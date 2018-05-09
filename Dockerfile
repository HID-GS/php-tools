FROM alpine:3.7

ENV PHPUNIT_VERSION 6.5.0
ENV DRUSH_VERSION 8.0.0
ENV TERMINUS_PLUGINS_DIR /tools/terminus/plugins
ENV TERMINUS_CACHE_DIR /tools/terminus/cache
ENV SIMPLETEST_DB sqlite://tmp/site.sqlite

RUN apk update && apk add --no-cache \
    curl \
    git \
    openssh-client \
    php7 \
    php7-ctype \
    php7-curl \
    php7-dom \
    php7-gd \
    php7-iconv \
    php7-json \
    php7-mbstring \
    php7-openssl \
    php7-phar \
    php7-pdo \
    php7-pdo_mysql \
    php7-pdo_sqlite \
    php7-session \
    php7-simplexml \
    php7-sqlite3 \
    php7-tokenizer \
    php7-xdebug \
    php7-xml \
    php7-xmlwriter \
    php7-zlib \
    rsync \
    && mkdir /composer \
    && curl --silent --show-error https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

COPY ./build-tools-ci.sh /scripts/

RUN mkdir -p ${TERMINUS_PLUGINS_DIR} ${TERMINUS_CACHE_DIR} \
    && composer -n global require -n hirak/prestissimo:^0.3 \
    && mkdir -p /tools/drupal \
    && cd /tools/drupal \
    && composer -n require drush/drush ^${DRUSH_VERSION} \
    && composer -n require drupal/coder \
    && /tools/drupal/vendor/bin/phpcs --config-set installed_paths /tools/drupal/vendor/drupal/coder/coder_sniffer \
    && mkdir -p /tools/php \
    && cd /tools/php \
    && composer -n require phpmd/phpmd \
    && composer -n require phpunit/phpunit ^${PHPUNIT_VERSION} \
    && mkdir -p /tools/terminus \
    && cd /tools/terminus \
    && composer -n require pantheon-systems/terminus \
    && composer create-project -n -d ${TERMINUS_PLUGINS_DIR} pantheon-systems/terminus-build-tools-plugin:~1 \
    && ls /tools/ | while read tool; do \
         ls /tools/$tool/vendor/bin/ | while read binary; do \
           rm -f /usr/local/bin/$binary; \
           ln -s /tools/$tool/vendor/bin/$binary /usr/local/bin; \
         done; \
       done \
    && touch ${HOME}/.bash_profile \
    && curl --silent --show-error https://platform.sh/cli/installer | php \
    && mv ${HOME}/.platformsh /tools/platformsh \
    && ln -s /tools/platformsh/bin/platform /usr/local/bin \
    && chmod +x /scripts/build-tools-ci.sh

WORKDIR /app

CMD ["phpcs", "--standard=Drupal,DrupalPractice", "."]
