#!/usr/bin/env bash

set -euo pipefail

function exit_error { echo "${1}" >&2; exit "${2:-1}"; }

ARGS=()
CONFIG="/etc/restic"
while [[ $# -gt 0 ]]; do
    key="${1}"
    case ${key} in
        -c|--config-dir)
        CONFIG="${2}"
        shift
        shift
        ;;
        *)
        ARGS+=("$1") # save it in an array for later
        shift # past argument
        ;;
    esac
done
set -- "${ARGS[@]}" 

[ -d "${CONFIG}" ] || exit_error "config dir does not exists: ${CONFIG}" 

source ${CONFIG}/restic.env

if [[ $RESTIC_PASSWORD_FILE != /* ]]; then
    RESTIC_PASSWORD_FILE="${CONFIG}/${RESTIC_PASSWORD_FILE}"
fi

if [[ $FILES_FROM != /* ]]; then
    FILES_FROM="${CONFIG}/${FILES_FROM}"
fi

KEEP_POLICY=(
    --keep-last=${KEEP_LAST}
    --keep-daily=${KEEP_DAILY}
    --keep-weekly=${KEEP_WEEKLY}
    --keep-monthly=${KEEP_MONTHLY}
    --keep-yearly=${KEEP_YEARLY}
)

function backup {
    "${BINARY}" backup \
		--files-from=${FILES_FROM} \
		--cache-dir=${CACHE_DIR} \
		--exclude-caches
    "${BINARY}" forget \
		--cache-dir=${CACHE_DIR} \
        --group-by="paths,tags" \
		--prune ${KEEP_POLICY[@]}
}

function check_subset {
    "${BINARY}" check \
    	--read-data-subset=$(($RANDOM % 4 + 1))/4
}

function check {
    "${BINARY}" check --read-data=true
}

case "$1" in
    --backup)
        backup
    ;;
    --check-subset)
        check_subset
    ;;
    --check)
        check
    ;;
    *)
        "${BINARY}" "${ARGS[@]}" --cache-dir=${CACHE_DIR}
    ;;
esac

