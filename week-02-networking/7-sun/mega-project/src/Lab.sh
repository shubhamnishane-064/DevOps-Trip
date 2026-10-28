#!/usr/bin/env bash
# lab.sh - one command to run the Nginx reverse proxy + load balancer lab
# Usage: ./lab.sh up            start 3 backends + Nginx (HTTP 8080, HTTPS 8443)
#        ./lab.sh test          check balancing, HTTPS and forwarded headers
#        ./lab.sh failover      stop backends one by one and watch Nginx cope
#        ./lab.sh demo          up + test + failover + down (exit 0 only if all checks pass)
#        ./lab.sh status | logs | stop-backend <1|2|3> | start-backend <1|2|3> | down
# Needs: nginx, python3, curl, openssl.  No root needed (ports above 1024).

set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN="${RUN_DIR:-$DIR/../.lab}"                      # all runtime files live here (logs, pids, certificate)
mkdir -p "$RUN"/{logs,tmp,tls,pids}
RUN="$(cd "$RUN" && pwd)"
HTTP_PORT="${HTTP_PORT:-8080}"
HTTPS_PORT="${HTTPS_PORT:-8443}"
BACKENDS=("9001:backend-1" "9002:backend-2" "9003:backend-backup")
FAILS=0

say()   { echo "$*"; }
pass()  { echo "  [PASS] $*"; }
fail()  { echo "  [FAIL] $*"; FAILS=$((FAILS + 1)); }

need() {                                            # check the tools exist
  local missing=0
  for c in nginx python3 curl openssl; do
    command -v "$c" >/dev/null 2>&1 || { echo "missing tool: $c   (Ubuntu: sudo apt install nginx python3 curl openssl)"; missing=1; }
  done
  return "$missing"
}

make_tls() {                                        # self-signed certificate, only for the lab
  [ -f "$RUN/tls/cert.pem" ] && return
  openssl req -x509 -newkey rsa:2048 -nodes -days 30 -subj "/CN=localhost" \
    -keyout "$RUN/tls/key.pem" -out "$RUN/tls/cert.pem" >/dev/null 2>&1
}

make_conf() {                                       # fill the template
  sed "s#@RUN@#$RUN#g; s#@HTTP_PORT@#$HTTP_PORT#g; s#@HTTPS_PORT@#$HTTPS_PORT#g" "$DIR/nginx.conf.tpl" > "$RUN/nginx.conf"
}

start_backend() {                                   # $1 = 1|2|3
  local entry="${BACKENDS[$(($1 - 1))]}" port name pidfile
  port="${entry%%:*}"; name="${entry##*:}"; pidfile="$RUN/pids/$name.pid"
  if [ -f "$pidfile" ] && kill -0 "$(cat "$pidfile")" 2>/dev/null; then say "  $name already running"; return; fi
  nohup python3 "$DIR/backend.py" "$port" "$name" >/dev/null 2>&1 < /dev/null &
  echo $! > "$pidfile"
  say "  started $name on port $port"
}

stop_backend() {                                    # $1 = 1|2|3
  local entry="${BACKENDS[$(($1 - 1))]}" name pidfile
  name="${entry##*:}"; pidfile="$RUN/pids/$name.pid"
  if [ -f "$pidfile" ] && kill "$(cat "$pidfile")" 2>/dev/null; then say "  stopped $name"; else say "  $name was not running"; fi
  rm -f "$pidfile"
}

nginx_running() { [ -f "$RUN/pids/nginx.pid" ] && kill -0 "$(cat "$RUN/pids/nginx.pid")" 2>/dev/null; }

up() {
  need || return 1
  make_tls; make_conf
  say "Checking the Nginx config..."
  nginx -t -c "$RUN/nginx.conf" -p "$RUN" 2>&1 | sed 's/^/  /'
  nginx -t -c "$RUN/nginx.conf" -p "$RUN" >/dev/null 2>&1 || { echo "config test failed"; return 1; }
  say "Starting backends..."
  for i in 1 2 3; do start_backend "$i"; done
  say "Waiting until every backend answers..."          # avoids a start-up race: Nginx must not see a backend that is not ready yet
  for entry in "${BACKENDS[@]}"; do
    for _ in $(seq 1 50); do
      [ "$(curl -s -o /dev/null -w '%{http_code}' --max-time 1 "http://127.0.0.1:${entry%%:*}/health")" = "200" ] && break
      sleep 0.1
    done
  done
  say "Starting Nginx..."
  if nginx_running; then nginx -s reload -c "$RUN/nginx.conf" -p "$RUN"; else nginx -c "$RUN/nginx.conf" -p "$RUN" 2>&1 | sed 's/^/  /'; fi
  for _ in $(seq 1 20); do                            # wait up to 4 s until everything answers
    [ "$(curl -s -o /dev/null -w '%{http_code}' --max-time 1 "http://127.0.0.1:$HTTP_PORT/nginx-health")" = "200" ] && break
    sleep 0.2
  done
  if [ "$(curl -s --max-time 2 "http://127.0.0.1:$HTTP_PORT/nginx-health")" = "ok" ]; then
    say "READY: http://localhost:$HTTP_PORT  and  https://localhost:$HTTPS_PORT  (curl -k for the self-signed certificate)"
  else
    echo "Nginx did not come up. Last lines of the error log:"; tail -n 5 "$RUN/logs/error.log" 2>/dev/null | sed 's/^/  /'
    return 1
  fi
}

down() {
  if nginx_running; then kill "$(cat "$RUN/pids/nginx.pid")" 2>/dev/null; say "  stopped nginx"; else say "  nginx was not running"; fi
  for i in 1 2 3; do stop_backend "$i"; done
}

status() {
  for entry in "${BACKENDS[@]}"; do
    port="${entry%%:*}"; name="${entry##*:}"
    code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 1 "http://127.0.0.1:$port/health")
    printf "  %-15s port %s: %s\n" "$name" "$port" "$([ "$code" = 200 ] && echo UP || echo DOWN)"
  done
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 1 "http://127.0.0.1:$HTTP_PORT/nginx-health")
  printf "  %-15s port %s: %s\n" "nginx (http)" "$HTTP_PORT" "$([ "$code" = 200 ] && echo UP || echo DOWN)"
}

declare -A COUNT
OKS=0; BAD=0
hits() {                                            # $1 = number of requests, $2 = url  -> fills COUNT, OKS, BAD
  local n="$1" url="${2:-http://127.0.0.1:$HTTP_PORT/}" code name
  COUNT=(); OKS=0; BAD=0
  for _ in $(seq 1 "$n"); do
    code=$(curl -sk --max-time 5 -o "$RUN/tmp/body" -w '%{http_code}' "$url")
    if [ "$code" = "200" ]; then
      name=$(head -n1 "$RUN/tmp/body" | awk '{print $3}')
      COUNT[$name]=$(( ${COUNT[$name]:-0} + 1 )); OKS=$((OKS + 1))
    else
      BAD=$((BAD + 1))
    fi
  done
}
show() { for k in "${!COUNT[@]}"; do printf "      %-15s %s\n" "$k" "${COUNT[$k]}"; done | sort; [ "$BAD" -gt 0 ] && echo "      failed requests $BAD"; }

do_test() {
  say "TEST 1: Nginx health URL"
  [ "$(curl -s "http://127.0.0.1:$HTTP_PORT/nginx-health")" = "ok" ] && pass "/nginx-health answers ok" || fail "/nginx-health"

  say "TEST 2: round robin, 20 requests over HTTP"
  hits 20; show
  if [ "${COUNT[backend-1]:-0}" -ge 8 ] && [ "${COUNT[backend-2]:-0}" -ge 8 ] && [ "${COUNT[backend-backup]:-0}" -eq 0 ] && [ "$BAD" -eq 0 ]; then
    pass "traffic shared between backend-1 and backend-2, backup unused, no errors"
  else fail "unexpected distribution"; fi

  say "TEST 3: HTTPS (self-signed certificate)"
  hits 4 "https://127.0.0.1:$HTTPS_PORT/"
  [ "$OKS" -eq 4 ] && pass "4 of 4 HTTPS requests OK" || fail "HTTPS requests failed ($BAD)"
  [ "$(curl -s -o /dev/null -w '%{http_code}' --max-time 3 "https://127.0.0.1:$HTTPS_PORT/")" = "000" ] \
    && pass "curl without -k rejects the self-signed certificate (as it should)" || fail "certificate was accepted without -k"

  say "TEST 4: client IP is forwarded to the backend"
  local body; body=$(curl -s "http://127.0.0.1:$HTTP_PORT/")
  echo "      $(echo "$body" | sed -n '2p')"
  echo "$body" | grep -q "X-Forwarded-For: 127.0.0.1" && pass "X-Forwarded-For reached the backend" || fail "X-Forwarded-For missing"

  say "TEST 5: access log shows the upstream"
  tail -n 2 "$RUN/logs/access.log" | sed 's/^/      /'
  grep -q "upstream=127.0.0.1:900" "$RUN/logs/access.log" && pass "upstream address is logged" || fail "no upstream in log"
}

do_failover() {
  say "FAILOVER 1: stop backend-1"
  stop_backend 1; sleep 0.5; hits 10; show
  [ "${COUNT[backend-2]:-0}" -eq 10 ] && pass "all 10 requests served by backend-2, no errors" || fail "requests lost"

  say "FAILOVER 2: stop backend-2 too -> the backup should answer"
  stop_backend 2; sleep 0.5; hits 10; show
  [ "${COUNT[backend-backup]:-0}" -eq 10 ] && pass "all 10 requests served by backend-backup" || fail "backup did not take over"

  say "FAILOVER 3: stop the backup -> nothing is left"
  stop_backend 3; sleep 0.5
  code=$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$HTTP_PORT/")
  [ "$code" = "502" ] && pass "Nginx returns 502 Bad Gateway" || fail "expected 502, got $code"
  echo "      error.log:"; grep -E "connect\(\) failed|no live upstreams" "$RUN/logs/error.log" | tail -n 2 | sed 's/.*\[error\]/        [error]/' | cut -c1-150

  say "FAILOVER 4: restart everything, wait for fail_timeout (5 s)"
  for i in 1 2 3; do start_backend "$i" >/dev/null; done
  sleep 6; hits 10; show
  [ "${COUNT[backend-1]:-0}" -ge 4 ] && [ "${COUNT[backend-2]:-0}" -ge 4 ] && [ "$BAD" -eq 0 ] && pass "back to sharing between backend-1 and backend-2" || fail "did not recover"
}

case "${1:-}" in
  up)            up ;;
  down)          down ;;
  status)        status ;;
  test)          do_test; echo "RESULT: $([ "$FAILS" -eq 0 ] && echo 'all checks passed' || echo "$FAILS check(s) failed")"; [ "$FAILS" -eq 0 ] ;;
  failover)      do_failover; echo "RESULT: $([ "$FAILS" -eq 0 ] && echo 'all checks passed' || echo "$FAILS check(s) failed")"; [ "$FAILS" -eq 0 ] ;;
  demo)          up || exit 1; do_test; do_failover; down; echo; echo "RESULT: $([ "$FAILS" -eq 0 ] && echo 'ALL CHECKS PASSED' || echo "$FAILS check(s) FAILED")"; [ "$FAILS" -eq 0 ] ;;
  logs)          tail -n 20 "$RUN/logs/access.log"; echo ---; tail -n 10 "$RUN/logs/error.log" ;;
  stop-backend)  stop_backend "${2:?give 1, 2 or 3}" ;;
  start-backend) start_backend "${2:?give 1, 2 or 3}" ;;
  *)             sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 2 ;;
esac
