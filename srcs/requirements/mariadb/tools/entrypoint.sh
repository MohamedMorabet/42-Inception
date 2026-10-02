#!/bin/sh
set -eu

: "${MYSQL_DATABASE:?MYSQL_DATABASE is missing}"
: "${MYSQL_USER:?MYSQL_USER is missing}"

# Keep names safe to insert into SQL.
case "$MYSQL_DATABASE" in
    ''|*[!a-zA-Z0-9_]*) echo "Invalid database name" >&2; exit 1 ;;
esac

case "$MYSQL_USER" in
    ''|root|*[!a-zA-Z0-9_]*) echo "Invalid database user" >&2; exit 1 ;;
esac

DB_PASSWORD=$(cat /run/secrets/db_password)
ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

[ -n "$DB_PASSWORD" ] && [ -n "$ROOT_PASSWORD" ] || {
    echo "Database passwords must not be empty" >&2
    exit 1
}

mkdir -p /run/mysqld /var/lib/mysql
chown -R mysql:mysql /run/mysqld /var/lib/mysql

if [ ! -d /var/lib/mysql/mysql ]; then
    mariadb-install-db \
        --user=mysql \
        --datadir=/var/lib/mysql \
        --auth-root-authentication-method=socket \
        --skip-test-db
fi

if [ ! -f /var/lib/mysql/.inception_initialized ]; then
    mariadbd --user=mysql --skip-networking &
    temporary_pid=$!

    # Stop the temporary server if setup fails.
    trap 'kill "$temporary_pid" 2>/dev/null || true' EXIT
    trap 'exit 1' INT TERM

    # Wait up to 30 seconds for MariaDB to become ready.
    attempts=0
    until mariadb --protocol=socket -uroot \
        -e "SELECT 1" >/dev/null 2>&1
    do
        attempts=$((attempts + 1))
        if [ "$attempts" -ge 30 ]; then
            echo "MariaDB failed to start" >&2
            exit 1
        fi
        sleep 1
    done

    # Escape quotes in passwords for SQL.
    db_password_sql=$(printf '%s' "$DB_PASSWORD" | sed "s/'/''/g")
    root_password_sql=$(printf '%s' "$ROOT_PASSWORD" | sed "s/'/''/g")

    mariadb --protocol=socket -uroot <<EOF
SET SESSION sql_mode = 'NO_BACKSLASH_ESCAPES';
CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\`;
CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%'
    IDENTIFIED BY '$db_password_sql';
ALTER USER '$MYSQL_USER'@'%'
    IDENTIFIED BY '$db_password_sql';
GRANT ALL PRIVILEGES ON \`$MYSQL_DATABASE\`.*
    TO '$MYSQL_USER'@'%';
SET PASSWORD FOR 'root'@'localhost'
    = PASSWORD('$root_password_sql');
EOF

    touch /var/lib/mysql/.inception_initialized

    kill "$temporary_pid"
    wait "$temporary_pid"
    trap - EXIT INT TERM
fi

exec mariadbd --user=mysql