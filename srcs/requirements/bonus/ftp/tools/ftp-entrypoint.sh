#!/bin/sh
set -eu

: "${FTP_USER:?FTP_USER is missing}"
: "${FTP_PASV_ADDRESS:?FTP_PASV_ADDRESS is missing}"

if ! id "$FTP_USER" >/dev/null 2>&1; then
    useradd --non-unique --uid 33 --gid www-data \
        --home-dir /var/www/html --shell /bin/bash "$FTP_USER"
fi

ftp_password=$(cat /run/secrets/ftp_password)
printf '%s:%s\n' "$FTP_USER" "$ftp_password" | chpasswd
unset ftp_password

printf '%s\n' "$FTP_USER" > /etc/vsftpd.userlist

sed -i '/^pasv_address=/d' /etc/vsftpd.conf
printf 'pasv_address=%s\n' "$FTP_PASV_ADDRESS" >> /etc/vsftpd.conf

exec "$@"
