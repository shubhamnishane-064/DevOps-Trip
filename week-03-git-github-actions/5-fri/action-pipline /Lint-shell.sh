#!/usr/bin/env bash
# lint_shell.sh - check every shell script under a folder (bash -n + ShellCheck)
# Used by the composite action "lint-shell", and runnable by hand:
#   bash lint_shell.sh [path] [severity]        e.g.  bash lint_shell.sh week-01-linux-bash warning
# Exit code: 0 = clean, 1 = problems found, 2 = wrong usage
# When GITHUB_OUTPUT is set, it also writes  count=<number of scripts>

set -uo pipefail

TARGET="${1:-.}"
SEVERITY="${2:-warning}"

case "$SEVERITY" in
  error|warning|info|style) ;;
  *) echo "::error::severity must be one of: error, warning, info, style (got '$SEVERITY')"; exit 2 ;;
esac
[ -d "$TARGET" ] || { echo "::error::path not found: $TARGET"; exit 2; }

mapfile -d '' FILES < <(find "$TARGET" -name '*.sh' -not -path '*/.git/*' -print0 | sort -z)
COUNT=${#FILES[@]}
echo "Found $COUNT shell script(s) under '$TARGET' (ShellCheck severity: $SEVERITY)"

FAIL=0
for f in "${FILES[@]}"; do
  bash -n "$f" || { echo "::error file=$f::syntax error"; FAIL=1; }
done

if [ "$COUNT" -gt 0 ]; then
  if command -v shellcheck >/dev/null 2>&1; then
    shellcheck --severity="$SEVERITY" -f gcc "${FILES[@]}" || FAIL=1
  else
    echo "::warning::shellcheck is not installed, only the syntax check ran"
  fi
fi

[ -n "${GITHUB_OUTPUT:-}" ] && echo "count=$COUNT" >> "$GITHUB_OUTPUT"

if [ "$FAIL" -eq 0 ]; then echo "OK: no problems"; else echo "FAILED: see the messages above"; fi
exit "$FAIL"