#!/bin/bash
set -e

/usr/local/bin/fixuid

# shellcheck disable=SC2001
ALIAS_CMD="$(echo "$0" | sed -e 's?/sbin/??')"

case "$ALIAS_CMD" in
    start|stop|restart|reload|status)
        exec service $1 $ALIAS_CMD
        ;;
esac

# check if there was a command passed
# required by Jenkins Docker plugin: https://github.com/docker-library/official-images#consistency
if [ "$1" ]; then
    # execute it
    exec "$@"
fi

case "$1" in
    list )
        exec service --status-all
        ;;
    reload-configuration )
        exec service $2 restart
        ;;
    start|stop|restart|reload|status)
        exec service $2 $1
        ;;
    \?)
        exec "$@"
        #exit 0
        ;;
esac
