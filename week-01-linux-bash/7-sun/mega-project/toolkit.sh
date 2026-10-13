#!/usr/bin/env bash
# toolkit.sh - Server Health & Backup Toolkit (runs all checks in one go)
# Usage: ./toolkit.sh [health|temp|backup|all]     (default: all)
#        CONFIG=/path/to/toolkit.conf ./toolkit.sh all
# Exit code: 0 = all good, 1 = warnings or a failed step

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${CONFIG:-$SCRIPT_DIR/toolkit.conf}"

if [ ! -r "$CONFIG" ]; then
  echo "ERROR: config file not found: $CONFIG"
  exit 2
fi
# shellcheck disable=SC1090
source "$CONFIG"

# settings the other scripts read from the environment
export DISK_LIMIT MEM_LIMIT SERVICES REPORT_DIR WARN_TEMP CRIT_TEMP

mkdir -p "$BACKUP_DIR" "$REPORT_DIR" "$(dirname "$LOG_FILE")"

MODE="${1:-all}"
PROBLEMS=0

log() { echo "$(date '+%F %T') $*" | tee -a "$LOG_FILE"; }

run_health() {
  log "--- HEALTH CHECK ---"
  if bash "$SCRIPT_DIR/healthcheck.sh" >/dev/null 2>&1; then
    log "OK    health check: system healthy"
  else
    log "WARN  health check: warnings found (see $REPORT_DIR)"
    PROBLEMS=$((PROBLEMS + 1))
  fi
}

run_temp() {
  log "--- TEMPERATURE ---"
  bash "$SCRIPT_DIR/temperature.sh" >/dev/null 2>&1
  case $? in
    0) log "OK    temperature normal" ;;
    1) log "WARN  temperature is high"; PROBLEMS=$((PROBLEMS + 1)) ;;
    2) log "CRIT  temperature is critical"; PROBLEMS=$((PROBLEMS + 1)) ;;
    3) log "SKIP  no temperature sensor (normal on VM / cloud)" ;;
    *) log "WARN  temperature script failed"; PROBLEMS=$((PROBLEMS + 1)) ;;
  esac
}

run_backup() {
  log "--- BACKUP ---"
  if [ ! -d "$SOURCE_DIR" ]; then
    log "WARN  backup skipped: $SOURCE_DIR does not exist"
    PROBLEMS=$((PROBLEMS + 1))
    return
  fi
  if bash "$SCRIPT_DIR/backup.sh" "$SOURCE_DIR" "$BACKUP_DIR" "$KEEP_DAYS" >/dev/null 2>&1; then
    log "OK    backup created in $BACKUP_DIR"
  else
    log "FAIL  backup failed"
    PROBLEMS=$((PROBLEMS + 1))
  fi
}

log "=========== TOOLKIT START ($MODE) on $(hostname) ==========="
case "$MODE" in
  health) run_health ;;
  temp)   run_temp ;;
  backup) run_backup ;;
  all)    run_health; run_temp; run_backup ;;
  *)      echo "Usage: $0 [health|temp|backup|all]"; exit 2 ;;
esac

if [ "$PROBLEMS" -eq 0 ]; then
  log "RESULT: ALL GOOD"
else
  log "RESULT: $PROBLEMS problem(s) found"
fi
log "=========== TOOLKIT END ==========="
[ "$PROBLEMS" -eq 0 ]