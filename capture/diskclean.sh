#!/usr/bin/env bash

# Strict mode: exit on error, error on unset variables, fail on pipe errors
set -euo pipefail

# Folder to monitor
DIR="/var/captures"

# Abort if the folder doesn't exist (catches typos / unmounted card)
[ -d "$DIR" ] || { echo "DIR not found: $DIR" >&2; exit 1; }

# Maximum folder size in MiB before cleanup starts (40 GiB = 40 * 1024)
THRESHOLD=40960

# Return the current folder size as a bare integer in MiB
# du -sBM = summarize total size in MiB blocks, output like "38000M  /var/captures"
# cut -f1 = keep the first field ("38000M")
# tr -dc '0-9' = strip everything except digits, leaving "38000"
usage() { du -sBM "$DIR" | cut -f1 | tr -dc '0-9'; }

# Count how many files we delete this run, for the summary line
deleted=0

# Keep deleting while the folder is at or over the size limit
while [ "$(usage)" -ge "$THRESHOLD" ]; do
    # Find the oldest file
    # find ... -printf '%T@ %p\n' = print each file's mtime timestamp + its path
    # sort -n = numeric sort, oldest timestamp first
    # head -1 = take that first line
    # cut -d' ' -f2- = drop the timestamp, keep the path (handles spaces in names)
    oldest=$(find "$DIR" -type f -printf '%T@ %p\n' | sort -n | head -1 | cut -d' ' -f2-)

    # Safety: if no file was found (folder empty), stop instead of looping forever
    [ -z "$oldest" ] && break

    # Delete that file (-f ignores errors if it's already gone)
    rm -f "$oldest"
    deleted=$((deleted + 1))

    # Print the deletion; oneshot stdout goes to the journal under the unit
    # View with: journalctl -u diskclean.service
    echo "deleted $oldest"
done

# Always print a one-line summary so each timer fire leaves a trace in the
# journal, even when nothing was deleted. Re-measure size after any deletions.
echo "run complete: deleted $deleted file(s), folder now $(usage) MiB / max $THRESHOLD MiB"