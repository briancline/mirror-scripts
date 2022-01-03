#!/bin/bash
set -o errexit

SCRIPT_PATH=$(readlink -f $0)
SCRIPT_NAME=$(basename $SCRIPT_PATH)
SCRIPT_DIR=$(dirname $SCRIPT_PATH)
LOGGER_NAME=${SCRIPT_NAME%%.*}
LOCK_FILE=${SCRIPT_DIR}/.lock.${LOGGER_NAME}
BASEDIR=$(dirname $SCRIPT_PATH)
source ${SCRIPT_DIR}/mirror-common.sh

MIRRORS_ROOT=/data/mirrors
export GNUPGHOME=$MIRRORS_ROOT/.keyring

release=focal,focal-backports,focal-security,focal-updates,bionic,bionic-backports,bionic-security,bionic-updates
section=main,universe,multiverse,restricted
arch=amd64,i386
proto=rsync
server=mirror.arizona.edu
in_path=/ubuntu
out_path="${MIRRORS_ROOT}/ubuntu"

lock

debmirror --verbose \
          --nosource \
          --rsync-options '-aL --partial --no-motd' \
          --rsync-batch 500 \
          --method $proto \
          -h $server \
          -r $in_path \
          -d $release \
          -s $section \
          -a $arch \
          $out_path \
          | logger -t $LOGGER_NAME -i

unlock
