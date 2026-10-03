#!/bin/sh
set -eu

: "${MYSQL_DATABASE:?MYSQL_DATABASE is missing}"
: "${MYSQL_USER:?MYSQL_USER is missing}"
: "${DOMAIN_NAME:?DOMAIN_NAME is missing}"
: "${WP_TITLE:?WP_TITLE is missing}"
: "${WP_OWNER_USER:?WP_OWNER_USER is missing}"
: "${WP_OWNER_EMAIL:?WP_OWNER_EMAIL is missing}"
: "${WP_USER:?WP_USER is missing}"
: "${WP_USER_EMAIL:?WP_USER_EMAIL is missing}"

owner_name=$(printf '%s' "$WP_OWNER_USER" | tr '[:upper:]' '[:lower:]')
case "$owner_name" in
    *admin*)
        echo "The WordPress administrator username must not contain admin." >&2
        exit 1
        ;;
esac

if [ "$WP_OWNER_USER" = "$WP_USER" ]; then
    echo "WordPress requires two distinct users." >&2
    exit 1
fi

db_password=$(cat /run/secrets/db_password)
owner_password=$(cat /run/secrets/wp_owner_password)
user_password=$(cat /run/secrets/wp_user_password)

export MYSQL_PWD="$db_password"

echo "Waiting for MariaDB at mariadb:3306..."
attempt=0
until mariadb --protocol=tcp --host=mariadb --port=3306 \
    --connect-timeout=2 --user="$MYSQL_USER" \
    "$MYSQL_DATABASE" --execute="SELECT 1;" >/dev/null 2>&1
do
    attempt=$((attempt + 1))
    if [ "$attempt" -ge 30 ]; then
        echo "MariaDB connection failed." >&2
        exit 1
    fi
    sleep 2
done

unset MYSQL_PWD
echo "MariaDB connection successful."

cd /var/www/html

if [ ! -f wp-includes/version.php ]; then
    wp core download --allow-root
fi

if [ ! -f wp-config.php ]; then
    wp config create --allow-root \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$db_password" \
        --dbhost="mariadb:3306"
fi

if ! wp core is-installed --allow-root; then
    wp core install --allow-root \
        --url="https://$DOMAIN_NAME" \
        --title="$WP_TITLE" \
        --admin_user="$WP_OWNER_USER" \
        --admin_password="$owner_password" \
        --admin_email="$WP_OWNER_EMAIL" \
        --skip-email
fi

if ! wp user get "$WP_USER" --allow-root >/dev/null 2>&1; then
    wp user create "$WP_USER" "$WP_USER_EMAIL" --allow-root \
        --role=subscriber \
        --user_pass="$user_password"
fi

chown -R www-data:www-data /var/www/html
chmod 640 /var/www/html/wp-config.php

unset db_password owner_password user_password
echo "Starting PHP-FPM..."
exec "$@"
