#!/bin/bash

set -ex

# start the docker daemon
/usr/local/bin/wrapdocker &

# start the ssh daemon
#/usr/sbin/sshd -D

# else default to run whatever the user wanted like "bash" or "sh"
/usr/local/bin/entrypoint.sh
