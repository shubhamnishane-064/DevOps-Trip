# Error Log: Nginx fails to start - "Address already in use"
## 1. Symptom (what I saw)
```
$ ./lab.sh up
Starting Nginx...
  nginx: [emerg] bind() to 0.0.0.0:8080 failed (98: Address already in use)
  nginx: [emerg] bind() to 0.0.0.0:8080 failed (98: Address already in use)
  ...
  nginx: [emerg] still could not bind()
Nginx did not come up. Last lines of the error log:
  [emerg] bind() to 0.0.0.0:8080 failed (98: Address already in use)
  [notice] try again to bind() after 500ms
  [emerg] still could not bind()
```

## 2. Context (what I was doing)
I started the lab with `./lab.sh up`. Earlier I had left a test web server running on port 8080 (`python3 -m http.server 8080`), and on a real machine the default Nginx service can also hold port 80/8080.

## 3. Investigation (how I debugged)
- [x] Read the message: `bind() ... failed (98: Address already in use)` means the port is **taken**
- [x] Found which program owns the port
- [x] Checked that it was not my own lab from an earlier run

Commands tried:
```bash
ss -tlnp | grep :8080
# LISTEN 0 5 0.0.0.0:8080  users:(("python3",pid=1286,fd=3))     -> a Python server owns it

ps -p 1286 -o pid,etime,cmd
# 1286  05:12  python3 -m http.server 8080                        -> my old test server

systemctl is-active nginx
# inactive                                                        -> the system Nginx is not the culprit
```

## 4. Root Cause
Two programs cannot listen on the same IP and port. A leftover Python test server was already bound to `0.0.0.0:8080`, so Nginx could not bind and kept retrying until it gave up.

## 5. Fix
```bash
kill 1286                      # stop the old process (or: sudo systemctl stop nginx if it was the system Nginx)
ss -tlnp | grep :8080          # nothing listed now
./lab.sh up                    # READY: http://localhost:8080 ...
```
Or keep the other program and use different ports:
```bash
HTTP_PORT=8081 HTTPS_PORT=8444 ./lab.sh up
```

## 6. Prevention / Lesson Learned
- **"Address already in use" = the port is already taken.** Always run `ss -tulpn | grep :PORT` first.
- `lab.sh up` now prints the last lines of `error.log` when Nginx does not come up, so the cause is visible immediately.
- Stop the default service when a lab needs the same ports: `sudo systemctl disable --now nginx`.
- Use `./lab.sh down` at the end of every session so no processes are left behind.
- Make ports configurable (`HTTP_PORT`, `HTTPS_PORT`) so a conflict can be solved without editing files.

## 7. Another problem I solved while building (summary)
**Start-up race:** my first full test run failed two checks (one request failed, and the backup server was skipped). Nginx was started before all backends were listening, so it marked servers as failed, and a `backup` entry has the defaults `max_fails=1` and `fail_timeout=10s`. Fix: wait for every backend's `/health` before starting Nginx. After the fix, three full demo runs passed.
