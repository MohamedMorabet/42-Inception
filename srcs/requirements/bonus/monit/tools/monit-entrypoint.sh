#!/bin/sh
set -eu

monitor_password=$(cat /run/secrets/monitor_password)

case "$monitor_password" in
    ''|*[!a-zA-Z0-9]*)
        echo "Monitoring password must contain only letters and numbers." >&2
        exit 1
        ;;
esac

umask 077
cp /etc/monit/monitrc.template /etc/monit/monitrc
printf 'allow "observer":"%s"\n' "$monitor_password" > /etc/monit/dashboard-auth
unset monitor_password

monit -t -c /etc/monit/monitrc
exec "$@"
