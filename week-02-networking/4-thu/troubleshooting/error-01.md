# Error Log: Nginx returns 502 Bad Gateway
## 1. Symptom (what I saw)
```
$ curl -i http://localhost:8080/
HTTP/1.1 502 Bad Gateway
Server: nginx/1.24.0 (Ubuntu)
...
<html><head><title>502 Bad Gateway</title></head> ...
```
Nginx itself answered, but the page from the application did not appear.

## 2. Context (what I was doing)
I had Nginx load balancing two test backends (ports 9001 and 9002). Both worked, then I stopped them to test failover. After stopping the second one, every request failed with 502.

## 3. Investigation (how I debugged)
- [x] Confirmed the status code with `curl -i`
- [x] Read the Nginx error log (the reason is always there)
- [x] Checked whether the backends are listening
- [x] Checked the `proxy_pass` / `upstream` ports

Commands tried:
```bash
sudo tail -n 5 /var/log/nginx/error.log
# [error] connect() failed (111: Connection refused) while connecting to upstream,
#   client: 127.0.0.1, request: "GET / HTTP/1.1", upstream: "http://127.0.0.1:9001/"
# [error] no live upstreams while connecting to upstream,
#   client: 127.0.0.1, request: "GET / HTTP/1.1", upstream: "http://myapp/"

sudo ss -tulpn | grep -E "9001|9002"
# (no output)                                  -> nothing is listening on either port

./backends.sh status
# port 9001: DOWN
# port 9002: DOWN

sudo nginx -t
# syntax is ok                                 -> the Nginx config is fine, so the problem is the backends
```

## 4. Root Cause
Nginx was working, but **both backends were down**.
- `connect() failed (111: Connection refused)` means "I reached the machine, but nothing is listening on that port."
- After `max_fails=2` failures, Nginx marked each server unavailable for `fail_timeout=10s`, so later requests logged `no live upstreams` and returned 502.

## 5. Fix
```bash
./backends.sh start                          # start both backends
./backends.sh status                         # port 9001: UP, port 9002: UP
sleep 12                                     # wait longer than fail_timeout (10 s)
curl -i http://localhost:8080/               # HTTP/1.1 200 OK
./lb_test.sh http://localhost:8080/ 10       # 50% / 50% again
```
For a real service: `sudo systemctl restart myapp`, then `systemctl status myapp` and `journalctl -u myapp -n 50` to find why it stopped.

## 6. Prevention / Lesson Learned
- **502 means the problem is behind Nginx.** Read `error.log` first, then check the app.
- Message guide: `Connection refused` = app not listening; `upstream timed out` = app too slow (504); `prematurely closed connection` = app crashed.
- A recovered backend is **not used instantly**: Nginx waits for `fail_timeout`. Remember this when testing.
- Add a `backup` server and several healthy backends, so one failure does not cause an outage. In my test, stopping one backend caused **no errors** because `proxy_next_upstream` retried on the other.
- Run the app as a systemd service with `Restart=on-failure`, and monitor it with an HTTP check (`httpcheck.sh` from Day 3).
- Always run `nginx -t` before `reload`.
