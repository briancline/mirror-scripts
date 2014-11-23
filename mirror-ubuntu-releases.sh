#!/bin/bash
set -ex

SCRIPT_PATH=$(readlink -f $0)
SCRIPT_NAME=$(basename $SCRIPT_PATH)
SCRIPT_DIR=$(dirname $SCRIPT_PATH)
LOGGER_NAME=${SCRIPT_NAME%%.*}
LOGGER_FACILITY=local7.info
LOCK_FILE=${SCRIPT_DIR}/.lock.${LOGGER_NAME}
BASEDIR=$(dirname $SCRIPT_PATH)
source ${SCRIPT_DIR}/mirror-common.sh

MIRRORS_ROOT=/mnt/mirrors.os01

RSYNC_SERVER=mirror.cogentco.com
RSYNC_SERVER=mirror.clarkson.edu
RSYNC_PATH=ubuntu-releases
RSYNC_SOURCE=rsync://${RSYNC_SERVER}/${RSYNC_PATH}

TARGET_PATH=${MIRRORS_ROOT}/${RSYNC_PATH}/

if [ ! -d $TARGET_PATH ]; then
    mkdir -p $TARGET_PATH
fi

lock

rsync --verbose \
      --progress \
      --recursive \
      --times \
      --links \
      --hard-links \
      --stats \
      --delete-after \
      $RSYNC_SOURCE \
      $TARGET_PATH \
      | logger -i -p ${LOGGER_FACILITY} -t $LOGGER_NAME

unlock
