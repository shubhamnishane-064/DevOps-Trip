# Networking for DevOps | Week 2 - Thursday: Nginx web server, reverse proxy and load balancer

## Today's Goal
Learn how Nginx serves websites, sits in front of applications as a reverse proxy, and shares traffic between several backends as a load balancer, and learn to debug it from its logs.

## Plan (checklist)
- [x] Learn the concept (web server, forward vs reverse proxy, upstream, balancing methods)
- [x] Build a reverse proxy and a load balancer with two backends
- [x] Test failover, a backup server and recovery
- [x] Write notes in `documentation/`
- [x] Log one error in `troubleshooting/`
- [x] Commit and push with a clear message

## What I Did
- Learned the config structure (`http`, `server`, `location`, `upstream`) and how `location` matching works.
- Wrote three configs: a static web server, a reverse proxy and a load balancer.
- Learned `proxy_pass`, the forwarded headers (`Host`, `X-Real-IP`, `X-Forwarded-For`, `X-Forwarded-Proto`) and timeouts.
- Learned balancing methods: round robin, `weight`, `least_conn`, `ip_hash`, plus `backup`, `down`, `max_fails` and `fail_timeout`.
- Built two test backends and a script that shows how requests are shared.
- Tested failure: one backend down (no errors), both down (502), backup takes over, recovery.
- Learned to read `error.log` messages (`Connection refused`, `no live upstreams`, `upstream timed out`).
- Practised the safe workflow: `nginx -t`, then `reload`.

## Files in this folder
| File | What it does |
|---|---|
| [`configs/static-site.conf`](configs/static-site.conf) | Nginx as a web server |
| [`configs/reverse-proxy.conf`](configs/reverse-proxy.conf) | Nginx in front of one app (HTTPS example commented) |
| [`configs/load-balancer.conf`](configs/load-balancer.conf) | `upstream` with 2 backends and a backup |
| [`backend.py`](backend.py) | Tiny test backend that shows its name and the client IP headers |
| [`backends.sh`](backends.sh) | `start`, `stop`, `status` or `stop-one <port>` for the backends |
| [`lb_test.sh`](lb_test.sh) | Sends N requests and prints how they were shared |

## Lab Summary
```bash
./backends.sh start
sudo cp configs/load-balancer.conf /etc/nginx/conf.d/
sudo nginx -t && sudo systemctl reload nginx
./lb_test.sh http://localhost:8080/ 20       # about 50% / 50%
./backends.sh stop-one 9001
./lb_test.sh http://localhost:8080/ 10       # all to backend-2, no errors
./backends.sh stop-one 9002
curl -i http://localhost:8080/               # 502 Bad Gateway
sudo tail -5 /var/log/nginx/error.log
```
Result: traffic was shared 50% / 50%, one backend failing caused no errors, both failing caused 502, and the error log pointed to the cause. (Add screenshots in `documentation/images/`.)

## What I Learned
- A reverse proxy hides and protects the servers; Nginx adds one entry point, HTTPS, balancing and caching.
- Without `X-Forwarded-For` the app sees only Nginx's IP.
- Open-source Nginx notices failures only from real traffic (`max_fails`, `fail_timeout`); a failed server is not retried instantly.
- 502 = bad answer from the backend, 503 = unavailable, 504 = timeout.
- `nginx -t` finds typos (a missing `;`) before they cause an outage.

## Errors Faced
- `502 Bad Gateway` (both backends down): see [`troubleshooting/error-01.md`](troubleshooting/error-01.md)

## Notes
Full notes: [`documentation/notes.md`](documentation/notes.md)

## Tomorrow
Day 5: firewalls (`ufw`, `iptables`, AWS Security Groups) and VPN basics.