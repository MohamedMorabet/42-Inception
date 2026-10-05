FROM debian:bookworm

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        php8.2-cli \
        php8.2-mysql \
        adminer \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/www/adminer \
    && printf '%s\n' '<?php require "/usr/share/adminer/adminer.php";' \
        > /var/www/adminer/index.php

WORKDIR /var/www/adminer

USER www-data

EXPOSE 8080

CMD ["php", "-S", "0.0.0.0:8080", "-t", "/var/www/adminer"]
