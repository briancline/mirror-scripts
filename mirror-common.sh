#!/bin/bash
set -e

log () {
    logger -t $LOGGER_NAME $*
}

lock () {
    local primary_pid=""

    if [ -f "${LOCK_FILE}" ]; then
        primary_pid=$(cat ${LOCK_FILE})
    fi

    if [[ -n "${primary_pid}" && -d "/proc/${primary_pid}/environ" ]]; then
        log "Another instance is already running, exiting"
        exit 1
    elif [ -n "${primary_pid}" ]; then
        log "Removing stale lockfile for pid ${primary_pid}"
        unlock
    fi

    echo $$ > $LOCK_FILE
}

unlock () {
    rm -f $LOCK_FILE
}

