#!/bin/bash
set -e

source /opt/bash-utils/logger.sh

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

function wait_for_process () {
  local max_time_wait=30
  local process_name="$1"
  local waited_sec=0
  while ! pgrep "$process_name" >/dev/null && ((waited_sec < max_time_wait)); do
    INFO "Process $process_name is not running yet. Retrying in 1 seconds"
    INFO "Waited $waited_sec seconds of $max_time_wait seconds"
    sleep 1
    ((waited_sec=waited_sec+1))
    if ((waited_sec >= max_time_wait)); then
      return 1
    fi
  done
  return 0
}

DEBUG "$0: - : $1"

INFO "Starting supervisor"
/usr/bin/supervisord -n >> /dev/null 2>&1 &

INFO "Waiting for processes to be running"
processes=(dockerd)

for process in "${processes[@]}"; do
  wait_for_process "$process"
  if [ $? -ne 0 ]; then
    ERROR "$process is not running after max time"
    exit 1
  else
    INFO "$process is running"
  fi
done

# loop around arguments string
for ARG in "$*"; do
  DEBUG "ARGS ITEM: $ARG"
done
# loop around arguments vector
for ARG in "$@"; do
  DEBUG "ARGV ITEM: $ARG"
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
  /usr/local/bin/jenkins-agent
  ;;
debug)
  /usr/local/bin/fixuid
  ;;
# match anything
*)
  DEBUG "EXEC : $@"
  docker-entrypoint.sh
  #exec "$@"
  #exit 0
  ;;
esac

# Wait processes to be running
/bin/bash
