FROM alpine:3.10

ENV PHPUNIT_VERSION 6.5.0
ENV PHPUNIT_CODE_COVERAGE_VERSION ~5
ENV DRUSH_VERSION 8.3.2
ENV TERMINUS_PLUGINS_DIR /tools/terminus/plugins
ENV TERMINUS_CACHE_DIR /tools/terminus/cache
ENV SIMPLETEST_DB sqlite://tmp/site.sqlite

RUN apk add --no-cache wget ca-certificates \
    && wget -O /etc/apk/keys/phpearth.rsa.pub https://repos.php.earth/alpine/phpearth.rsa.pub \
    && echo "https://repos.php.earth/alpine/v3.9" >> /etc/apk/repositories \
    && apk add --no-cache build-base autoconf --virtual .build-deps \
    && apk add --no-cache \
      bash \
      curl \
      git \
      mariadb-dev \
      mariadb-client \
      openssh-client \
      patch \
      php7.3 \
      php7.3-fpm \
      php7.3-opcache \
      php7.3-curl \
      php7.3-bcmath \
      php7.3-bz2 \
      php7.3-calendar \
      php7.3-ctype \
      php7.3-dba \
      php7.3-dom \
      php7.3-exif \
      php7.3-fileinfo \
      php7.3-gd \
      php7.3-gettext \
      php7.3-gmp \
      php7.3-iconv \
      php7.3-json \
      php7.3-ldap \
      php7.3-mbstring \
      php7.3-memcached \
      php7.3-mysqli \
      php7.3-mysqlnd \
      php7.3-openssl \
      php7.3-pcntl \
      php7.3-pdo \
      php7.3-pdo_mysql \
      php7.3-pdo_sqlite \
      php7.3-pear \
      php7.3-phar \
      php7.3-posix \
      php7.3-redis \
      php7.3-session \
      php7.3-shmop \
      php7.3-simplexml \
      php7.3-soap \
      php7.3-sockets \
      php7.3-sqlite3 \
      php7.3-sysvmsg \
      php7.3-sysvsem \
      php7.3-sysvshm \
      php7.3-tokenizer \
      php7.3-wddx \
      php7.3-xdebug \
      php7.3-xml \
      php7.3-xmlreader \
      php7.3-xmlwriter \
      php7.3-xsl \
      php7.3-zip \
      php7.3-zlib \
      rsync \
    && mkdir /composer \
    && curl --silent --show-error https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

COPY ./build-tools-ci.sh /scripts/
COPY ./version /usr/local/bin/

RUN mkdir -p ${TERMINUS_PLUGINS_DIR} ${TERMINUS_CACHE_DIR} \
    && composer -n global require -n hirak/prestissimo:^0.3 \
    && mkdir -p /tools/drupal \
    && cd /tools/drupal \
    && composer -n require drush/drush ^${DRUSH_VERSION} \
    && composer -n require drupal/coder \
    && /tools/drupal/vendor/bin/phpcs --config-set installed_paths /tools/drupal/vendor/drupal/coder/coder_sniffer \
    && mkdir -p /tools/drupalconsole \
    && cd /tools/drupalconsole \
    && composer require drupal/console \
    && mkdir -p /tools/php \
    && cd /tools/php \
    && composer -n require phpmd/phpmd \
    && composer -n require sebastian/phpcpd \
    && composer -n require phing/phing \
    && mkdir -p /tools/phpunit \
    && cd /tools/phpunit \
    && composer -n require phpunit/php-code-coverage ${PHPUNIT_CODE_COVERAGE_VERSION} \
    && composer -n require phpunit/phpunit ^${PHPUNIT_VERSION} \
    && mkdir -p /tools/terminus \
    && cd /tools/terminus \
    && composer -n require pantheon-systems/terminus \
    && composer create-project -n -d ${TERMINUS_PLUGINS_DIR} pantheon-systems/terminus-build-tools-plugin:^2.0.0-beta13 \
    && mkdir -p /tools/phpstan \
    && cd /tools/phpstan \
    && composer require mavimo/phpstan-junit \
    && composer require mglaman/phpstan-drupal \
    && composer require phpstan/phpstan-deprecation-rules \
    && composer require phpstan/extension-installer \
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
    && chmod +x /scripts/build-tools-ci.sh \
    && chmod +x /usr/local/bin/version \
    && mkdir -p /tools/phpdocumentor \
    && cd /tools/phpdocumentor \
    && composer require jms/serializer:1.7.* \
    && composer require phpdocumentor/phpdocumentor \
    && mkdir -p /tools/codeception \
    && cd /tools/codeception \
    && composer require codeception/codeception \
    && apk del .build-deps \
    && mkdir -p /tools/drupal/vendor/drupal/coder/coder_sniffer/DrupalAll

RUN sed -i 's/^memory_limit = 128M/memory_limit = 1024M/g' /etc/php/7.3/php.ini

COPY phpcs-rules/DrupalAll-ruleset.xml /tools/drupal/vendor/drupal/coder/coder_sniffer/DrupalAll/ruleset.xml

RUN logfile="/version.txt" \
    && > $logfile \
    && echo "" >> $logfile \
    && echo "build timestamp: $(date)" >> $logfile \
    && echo "" >> $logfile \
    && php --version | sed -ne 's/^\(PHP [^ ]\+\) .*/\1/gp' >> $logfile \
    && pecl list | tail -n +4 >> $logfile \
    && composer --version >> $logfile \
    && /tools/drupal/vendor/bin/drush --version >> $logfile \
    && /tools/drupal/vendor/bin/phpcs --version >> $logfile \
    && /tools/drupal/vendor/bin/phpcs -i >> $logfile \
    && composer -d/tools/drupalconsole show | grep drupal | head -n 1 >> $logfile \
    && /tools/php/vendor/bin/phpmd --version >> $logfile \
    && /tools/php/vendor/bin/phing -v >> $logfile \
    && /tools/php/vendor/bin/phpcpd --version >> $logfile \
    && /tools/phpunit/vendor/bin/phpunit --version >> $logfile \
    && /tools/phpdocumentor/vendor/bin/phpdoc --version >> $logfile \
    && /tools/codeception/vendor/bin/codecept --version >> $logfile \
    && /tools/phpstan/vendor/bin/phpstan --version >> $logfile \
    && terminus --version >> $logfile \
    && platform --version >> $logfile

WORKDIR /app

CMD ["phpcs", "--standard=Drupal,DrupalPractice", "."]
