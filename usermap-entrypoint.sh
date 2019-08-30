#!/bin/bash

# A QAD script to override the UID/GID of the entrypoint user of a docker image
# at runtime, i.e. without rebuilding.
#
# Run using the following incantation:
#
# docker run -u root -v ./usermap-entrypoint.sh:/tmp/entrypoint.sh --entrypoint=/tmp/entrypoint.sh \
#   -e NAME=VALUE -e NAME=VALUE ... \
#   -d -name foo foo:latest
#
# The defaults are overridden by supplying environment variables via `-e`.

### DEFAULTS ###

[[ $MAP_USER ]] || MAP_USER=$(getent passwd |awk -F: '$3==1000 {print $1}')
[[ $MAP_GROUP ]] || MAP_GROUP=$(groups $MAP_USER|awk '{print $3}')
[[ $NEW_UID ]] || NEW_UID=65534
[[ $NEW_GID ]] || NEW_GID=65534
# The location of the real entrypoint
[[ $ENTRYPOINT ]] || ENTRYPOINT=/usr/local/bin/entrypoint.sh

###

OLD_UID=$(id -u $MAP_USER)
OLD_GID=$(getent group|awk -F: '/^'"$MAP_GROUP"'/ {print $3}')

groupmod --gid $NEW_GID $MAP_GROUP
usermod --uid $NEW_UID --gid $NEW_GID $MAP_USER

find / -uid $OLD_UID -exec chown $NEW_UID {} \;
find / -gid $OLD_GID -exec chgrp $NEW_GID {} \;

runuser -u $MAP_USER $ENTRYPOINT
