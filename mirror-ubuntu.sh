#!/bin/bash
set -e

SCRIPT_PATH=$(readlink -f $0)
SCRIPT_NAME=$(basename $SCRIPT_PATH)
SCRIPT_DIR=$(dirname $SCRIPT_PATH)
LOGGER_NAME=${SCRIPT_NAME%%.*}
LOCK_FILE=${SCRIPT_DIR}/.lock.${LOGGER_NAME}
BASEDIR=$(dirname $SCRIPT_PATH)
source ${SCRIPT_DIR}/mirror-common.sh

MIRRORS_ROOT=/mnt/mirrors.os01
export GNUPGHOME=$MIRRORS_ROOT/keyring

release=precise,precise-security,precise-updates,precise-backports,saucy,saucy-security,saucy-updates,saucy-backports,trusty,trusty-security,trusty-updates,trusty-backports
section=main,restricted,universe,multiverse
arch=amd64,i386
proto=http
#server=mirror.clarkson.edu
server=ftp.utexas.edu
in_path=/ubuntu
out_path="${MIRRORS_ROOT}/ubuntu"

lock

debmirror --verbose \
          --source \
          --method $proto \
          -h $server \
          -r $in_path \
          -d $release \
          -s $section \
          -a $arch \
          $out_path \
          | logger -t $LOGGER_NAME -i

unlock
