#!/usr/bin/env bash

BUILDER_USER=plasma
BUILDER_GROUP=animist
OB_POOLS_DIR=/var/ob/pools
PLASMA_INSTALL=${PLASMA_INSTALL:-/opt/plasma}

# If we are running docker natively, we want to create a user in the container
# with the same UID and GID as the user on the host machine, so that any files
# created are owned by that user. Without this they are all owned by root.
# The BUILDER_UID and BUILDER_GID vars must be provided by the environment.
if [[ -n $BUILDER_UID ]] && [[ -n $BUILDER_GID ]]; then

    groupadd -o -g "$BUILDER_GID" "$BUILDER_GROUP" 2> /dev/null
    useradd -o -m -g "$BUILDER_GID" -u "$BUILDER_UID" -s /bin/bash "$BUILDER_USER" 2> /dev/null
    adduser "$BUILDER_USER" sudo
    export HOME=/home/${BUILDER_USER}
    shopt -s dotglob
    cp -r /etc/skel/* $HOME/
    chown -R $BUILDER_UID:$BUILDER_GID $HOME
    mkdir -p $OB_POOLS_DIR
    chown -R $BUILDER_UID:$BUILDER_GID $OB_POOLS_DIR
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
    cat <<-EOF >> ~/.profile

PLASMA_INSTALL=$PLASMA_INSTALL
# set PATH so it includes plasma, if it exists
if [ -d "$PLASMA_INSTALL/bin" ] ; then
    PATH="$PLASMA_INSTALL/bin:$PATH"
fi
EOF


    # Run the command as the specified user/group.
    if [[ "$@" == "$SHELL" ]]; then
        su - "$BUILDER_USER"
    else
        su "$BUILDER_USER" -c "$@"
    fi
else
    # Just run the command as root.
    exec "$@"
fi
