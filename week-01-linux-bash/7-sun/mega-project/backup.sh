#!/usr/bin/env bash
# backup.sh - compress a folder into a dated .tar.gz and delete old backups
# Usage: ./backup.sh <source_folder> [backup_folder] [keep_days]
# Example: ./backup.sh /home/shubham/projects /home/shubham/backups 7

set -euo pipefail

SOURCE="${1:-}"
DEST="${2:-$HOME/backups}"
KEEP_DAYS="${3:-7}"

if [ -z "$SOURCE" ]; then
  echo "Usage: $0 <source_folder> [backup_folder] [keep_days]"
  exit 2
fi
if [ ! -d "$SOURCE" ]; then
  echo "ERROR: source folder '$SOURCE' does not exist"
  exit 1
fi

mkdir -p "$DEST"
LOG_FILE="$DEST/backup.log"
NAME="$(basename "$SOURCE")"
STAMP="$(date +%F_%H-%M-%S)"
ARCHIVE="$DEST/${NAME}_${STAMP}.tar.gz"

log() { echo "$(date '+%F %T') $*" | tee -a "$LOG_FILE"; }

log "START backup of $SOURCE"

# -C goes to the parent folder, so the archive holds a clean relative path
tar -czf "$ARCHIVE" -C "$(dirname "$SOURCE")" "$NAME"

# check the archive can be read
if tar -tzf "$ARCHIVE" >/dev/null; then
  SIZE="$(du -h "$ARCHIVE" | cut -f1)"
  log "OK created $ARCHIVE ($SIZE)"
else
  log "ERROR archive is damaged: $ARCHIVE"
  exit 1
fi

# keep only the last KEEP_DAYS days of backups for this folder
DELETED=$(find "$DEST" -name "${NAME}_*.tar.gz" -type f -mtime +"$KEEP_DAYS" -print -delete | wc -l)
log "CLEANUP removed $DELETED backup(s) older than $KEEP_DAYS days"

log "DONE"