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

server=archive.raspbian.org
in_path=archive
out_path=${MIRRORS_ROOT}/raspbian

lock

rsync --archive \
      --verbose \
      --delete \
      --delete-delay \
      --delay-updates \
      $server::$in_path \
      $out_path \
      | logger -t $LOGGER_NAME -i

unlock
