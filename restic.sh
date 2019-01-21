#!/usr/bin/env bash

set -euo pipefail

source ~/restic.env

KEEP_POLICY=(
	--keep-last=2
	--keep-daily=7
	--keep-weekly=8
	--keep-monthly=12
	--keep-yearly=10
)

function backup {
	~/bin/restic backup \
		--files-from=${RESTIC_FILESFROM} \
		--tag=cron \
		--cache-dir=${RESTIC_CACHEDIR} \
		--exclude-caches
	~/bin/restic forget \
		--tag=cron \
		--cache-dir=${RESTIC_CACHEDIR} \
		--prune ${KEEP_POLICY[@]}
}

function check {
	~/bin/restic check \
		--read-data-subset=$(($RANDOM % 4 + 1))/4
}

case "$1" in
	--backup)
		backup
		;;
	--check)
		check
		;;
	*)
		~/bin/restic "$@" \
			--cache-dir=${RESTIC_CACHEDIR}
		;;
esac

