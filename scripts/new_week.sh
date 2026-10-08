#!/usr/bin/env bash
# usage: ./scripts/new_week.sh 13 my-topic
set -euo pipefail
N=$(printf "%02d" "$1"); SLUG="$2"
BASE="week-$N-$SLUG"
i=1
for d in mon tue wed thu fri sat sun; do
  mkdir -p "$BASE/$i-$d/documentation" "$BASE/$i-$d/troubleshooting"
  cp templates/daily-readme.md "$BASE/$i-$d/README.md"
  cp templates/error-template.md "$BASE/$i-$d/troubleshooting/error-01.md"
  touch "$BASE/$i-$d/documentation/notes.md"
  i=$((i+1))
done
mkdir -p "$BASE/7-sun/mega-project/src" "$BASE/quick-revision"
cp templates/mega-project-template.md "$BASE/7-sun/mega-project/README.md"
touch "$BASE/quick-revision/cheatsheet.md" "$BASE/quick-revision/interview-questions.md"
echo "Created $BASE"
