# Networking for DevOps | Week 2 - Sunday: Mega Project

## Today's Goal
Combine the week's networking skills into one project I can show to recruiters: an **Nginx reverse proxy and load balancer lab** with HTTPS, failover and automatic tests.

## Plan (checklist)
- [x] Design the setup (Nginx, 2 backends, 1 backup, HTTP and HTTPS)
- [x] Write the Nginx config template and the Python backend
- [x] Write `lab.sh` (up, test, failover, demo, down)
- [x] Test normal and failure cases, several runs in a row
- [x] Write the project README with a diagram
- [x] Write notes and one error log
- [x] Commit and push with a clear message

## What I Did
- Built an `nginx.conf` **template** and a script that fills in paths and ports, so the lab runs on any machine without root.
- Configured Nginx as a reverse proxy and load balancer: round robin, `max_fails` and `fail_timeout`, `proxy_next_upstream`, a `backup` server, forwarded client-IP headers and a custom log format that shows `upstream=`.
- Added HTTPS with a self-signed certificate created by the script.
- Wrote `lab.sh`: `up`, `down`, `status`, `test`, `failover`, `demo`, `logs`, `stop-backend`, `start-backend`.
- Tested: even sharing (10 / 10), HTTPS, forwarded headers, one backend down (no errors), two down (backup answers), all down (502 plus `no live upstreams` in the log), and recovery after `fail_timeout`.
- Found and fixed a start-up race (Nginx started before the backends were ready), then ran the full demo three times with all checks passing.
- Hit and documented a port conflict (`Address already in use`).

## Project
Go to the project folder: [`mega-project/`](mega-project/README.md)

| File | What it does |
|---|---|
| [`src/lab.sh`](mega-project/src/lab.sh) | Starts, tests, breaks and stops the whole lab; exit code 0 only if all checks pass |
| [`src/nginx.conf.tpl`](mega-project/src/nginx.conf.tpl) | Nginx config template |
| [`src/backend.py`](mega-project/src/backend.py) | Tiny Python test backend |

## Lab Summary
```bash
cd mega-project/src
chmod +x lab.sh backend.py
./lab.sh demo
echo $?                      # 0 = all checks passed
```
Result: all checks passed (balancing, HTTPS, headers, logging, failover, backup, 502 when everything is down, recovery). (Add screenshots in `mega-project/docs/`.)

## What I Learned
- Wait until services are really ready; a fixed `sleep` or no wait causes races.
- Failed servers stay out for `fail_timeout`, and `backup` entries default to `max_fails=1`, `fail_timeout=10s`.
- `proxy_next_upstream` hides a single backend failure from users.
- Test the failure cases, and keep the logs that explain them.
- A project needs a diagram, tests, an error log and a clear README.

## Errors Faced
- `bind() to 0.0.0.0:8080 failed (98: Address already in use)`: see [`troubleshooting/error-01.md`](troubleshooting/error-01.md)

## Notes
Full notes: [`documentation/notes.md`](documentation/notes.md)

## Next Week
Week 3: Git and GitHub Actions (branching, pull requests, workflows, matrix builds, secrets, caching, reusable workflows).