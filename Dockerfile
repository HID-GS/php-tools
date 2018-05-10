FROM alpine:3.7

ENV PHPUNIT_VERSION 6.5.0
ENV DRUSH_VERSION 8.0.0
ENV TERMINUS_PLUGINS_DIR /tools/terminus/plugins
ENV TERMINUS_CACHE_DIR /tools/terminus/cache
ENV SIMPLETEST_DB sqlite://tmp/site.sqlite

RUN apk add --no-cache wget ca-certificates \
    && wget -O /etc/apk/keys/phpearth.rsa.pub https://repos.php.earth/alpine/phpearth.rsa.pub \
    && echo "https://repos.php.earth/alpine/v3.7" >> /etc/apk/repositories \
    && apk update && apk add --no-cache \
    curl \
    git \
    openssh-client \
    php7.2 \
    php7.2-ctype \
    php7.2-curl \
    php7.2-dom \
    php7.2-gd \
    php7.2-iconv \
    php7.2-json \
    php7.2-mbstring \
    php7.2-openssl \
    php7.2-phar \
    php7.2-pdo \
    php7.2-pdo_mysql \
    php7.2-pdo_sqlite \
    php7.2-session \
    php7.2-simplexml \
    php7.2-sqlite3 \
    php7.2-tokenizer \
    php7.2-xdebug \
    php7.2-xml \
    php7.2-xmlwriter \
    php7.2-zlib \
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
