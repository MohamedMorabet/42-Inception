#!/bin/sh
set -eu

mkdir -p /etc/nginx/ssl

if [ ! -s /etc/nginx/ssl/server.crt ] || [ ! -s /etc/nginx/ssl/server.key ]; then
    openssl req -x509 -nodes -newkey rsa:2048 \
        -days 365 \
        -keyout /etc/nginx/ssl/server.key \
        -out /etc/nginx/ssl/server.crt \
        -subj "/CN=mel-mora.42.fr" \
        -addext "subjectAltName=DNS:mel-mora.42.fr"
fi

chmod 600 /etc/nginx/ssl/server.key

nginx -t

exec "$@"
