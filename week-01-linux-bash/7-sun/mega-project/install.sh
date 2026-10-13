#!/usr/bin/env bash
# install.sh - add (or remove) the toolkit cron jobs
# Usage: ./install.sh --print      show the cron lines only (safe preview)
#        ./install.sh --install    add the jobs to my crontab
#        ./install.sh --remove     remove the jobs again

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TAG="# devops-toolkit"
LINES=$(cat <<CRON
*/30 * * * * /bin/bash $SCRIPT_DIR/toolkit.sh health >/dev/null 2>&1 $TAG
0 2 * * * /bin/bash $SCRIPT_DIR/toolkit.sh backup >/dev/null 2>&1 $TAG
CRON
)

case "${1:-}" in
  --print)
    echo "$LINES"
    ;;
  --install)
    command -v crontab >/dev/null || { echo "crontab not found (sudo apt install cron)"; exit 1; }
    # keep other jobs, remove old toolkit lines, add the new ones
    ( crontab -l 2>/dev/null | grep -vF "$TAG" || true; echo "$LINES" ) | crontab -
    echo "Installed. Check with: crontab -l"
    ;;
  --remove)
    command -v crontab >/dev/null || { echo "crontab not found"; exit 1; }
    ( crontab -l 2>/dev/null | grep -vF "$TAG" || true ) | crontab -
    echo "Removed toolkit cron jobs."
    ;;
  *)
    echo "Usage: $0 --print | --install | --remove"
    exit 2
    ;;
esac