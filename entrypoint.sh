#!/bin/bash
set -e

# shellcheck disable=SC2001
#ALIAS_CMD="$(echo "$0" | sed -e 's?/sbin/??')"
#
#case "$ALIAS_CMD" in
#    start|stop|restart|reload|status)
#        exec service $1 $ALIAS_CMD
#        ;;
#esac

# check if there was a command passed
# required by Jenkins Docker plugin: https://github.com/docker-library/official-images#consistency
#if [ "$1" ]; then
#    # execute it
#    exec "$@"
#fi

echo "$0: DEBUG : $1"

# loop around arguments string
for ARG in "$*"; do
  echo "ARGS ITEM: $ARG"
done
# loop around arguments vector
for ARG in "$@"; do
  echo "ARGV ITEM: $ARG"
done

sh -c "sudo chown -R jenkins /github"
sh -c "sudo chmod -R 777 /github"

case "$1" in
list)
  exec service --status-all
  ;;
reload-configuration)
  exec service $2 restart
  ;;
start | stop | restart | reload | status)
  exec service $2 $1
  ;;
agent)
  /usr/local/bin/jenkins-agent && bash
  ;;
debug)
  /usr/local/bin/fixuid && bash
  ;;
# match anything
*)
  echo "EXEC : $@"
  exec "$@"
  #exit 0
  ;;
esac
