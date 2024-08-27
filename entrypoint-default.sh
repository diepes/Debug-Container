#!/bin/sh
set -e

echo "# entrypoint-default.sh running ..."

if [ "$1" = 'sshd' ]; then
    exec "/entrypoint-sshd.sh"
else
    exec "$@"
fi

echo "# entrypoint-default.sh The END."
