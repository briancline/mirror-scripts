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

release=bullseye,bullseye-updates,bullseye-backports,buster,buster-updates,buster-backports
section=main,contrib,non-free,main/debian-installer
arch=amd64,i386
proto=http
server=mirror.clarkson.edu
#server=mirror.cogentco.com
in_path=/debian
out_path="${MIRRORS_ROOT}/debian"

lock

debmirror --verbose \
          --nosource \
          --diff=none \
          --rsync-extra=doc,indices,tools,trace \
          --method $proto \
          -h $server \
          -r $in_path \
          -d $release \
          -s $section \
          -a $arch \
          $out_path \
          | logger -t $LOGGER_NAME -i

unlock
