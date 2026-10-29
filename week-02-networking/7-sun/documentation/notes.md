# Notes: Day 7 - Mega Project (Nginx Reverse Proxy & Load Balancer Lab)

**Week 2 | Sunday** | Topic: combine the week's networking skills into one project I can show to recruiters

---

## 1. Goal
Build and prove a small, realistic setup:
1. Nginx in front of several app servers (reverse proxy + load balancer)
2. HTTPS at the front door
3. Failover: users keep working when a server dies
4. One script that starts it, tests it, breaks it on purpose and cleans up

Why this project? Almost every production web system looks like this: **users -> load balancer / reverse proxy -> app servers**.

---

## 2. What I Reused from Week 2

| Day | Skill | Where it is used |
|---|---|---|
| Mon | IPs, ports, subnets, localhost vs `0.0.0.0` | Backends on `127.0.0.1:9001-9003`, Nginx on `8080/8443` |
| Tue | DNS, `/etc/hosts` | `localhost` resolves; `server_name` and the `Host` header |
| Wed | HTTP, status codes, TLS, `curl` | 200 / 502 checks, HTTPS with a certificate, `curl -k` |
| Thu | Nginx: `proxy_pass`, `upstream`, `backup`, `max_fails` | The whole config |
| Fri | Firewalls (planned) | Ports above 1024 only; same ideas for Security Groups later |
| Sat | `ss`, `tcpdump`, open vs refused vs timeout | Found the port conflict and the start-up race |

---

## 3. Design

```
                       Nginx (@ 8080 HTTP, 8443 HTTPS)
 client  ------------>   upstream "myapp"
                              |
              +---------------+-----------------+
              |                                 |
        backend-1 :9001                  backend-2 :9002          <- round robin
                                                |
                                  backend-backup :9003            <- only if both are down
```

| File | Job |
|---|---|
| `src/nginx.conf.tpl` | Nginx config **template**; contains placeholders such as `@RUN@` and `@HTTP_PORT@` |
| `src/lab.sh` | Fills the template, creates the certificate, starts everything, runs the checks, stops everything |
| `src/backend.py` | Tiny Python web server: answers with its own name, and shows the client IP headers it received |

Runtime files (logs, PID files, certificate, generated config) go to `.lab/`, which is git-ignored.

---

## 4. Ideas Used (simple explanation)

### Template + generated config
```bash
sed "s#@RUN@#$RUN#g; s#@HTTP_PORT@#$HTTP_PORT#g" nginx.conf.tpl > nginx.conf
```
One template, different ports and paths per machine. This is the same idea as Ansible and Terraform templates later.

### Running Nginx without root
```bash
nginx -t -c "$RUN/nginx.conf" -p "$RUN"      # test with my own config and prefix folder
nginx    -c "$RUN/nginx.conf" -p "$RUN"      # start it
nginx -s reload -c ... -p ...                # reload
kill "$(cat $RUN/pids/nginx.pid)"            # stop it using the PID file
```
Ports above 1024 and my own `pid`, log and temp paths mean no `sudo` is needed.

### PID files for background programs
```bash
nohup python3 backend.py 9001 backend-1 >/dev/null 2>&1 < /dev/null &
echo $! > pids/backend-1.pid            # $! = PID of the last background job
kill -0 "$(cat pids/backend-1.pid)"     # is it still alive? (sends no signal, only checks)
```

### Readiness wait instead of a fixed `sleep`
```bash
for _ in $(seq 1 50); do
  [ "$(curl -s -o /dev/null -w '%{http_code}' --max-time 1 "http://127.0.0.1:$port/health")" = 200 ] && break
  sleep 0.1
done
```
Wait until the thing really answers, not "long enough".

### Counting results with an associative array
```bash
declare -A COUNT
COUNT[$name]=$(( ${COUNT[$name]:-0} + 1 ))
```

### Checks that set the exit code
`pass()` and `fail()` print the result and count failures; at the end `[ "$FAILS" -eq 0 ]` makes the script exit 0 only if everything passed. That lets CI or cron use it.

### Access log that shows the backend
```nginx
log_format lab '$remote_addr [$time_local] "$request" $status upstream=$upstream_addr rt=$request_time';
```
`upstream=127.0.0.1:9002` proves which backend served each request.

---

## 5. Commands to Run

```bash
sudo apt install nginx python3 curl openssl -y
cd week-02-networking/7-sun/mega-project/src
chmod +x lab.sh backend.py

./lab.sh demo               # full run, exit code 0 = all checks passed

./lab.sh up
curl http://localhost:8080/
curl -k https://localhost:8443/
./lab.sh status
./lab.sh test
./lab.sh failover
./lab.sh logs
./lab.sh down
```

### Things to try by hand (and screenshot)
1. `for i in 1 2 3 4; do curl -s http://localhost:8080/ | head -1; done` and watch the names alternate.
2. `./lab.sh stop-backend 1`, then curl again: still no errors.
3. `./lab.sh stop-backend 2`: the **backup** answers.
4. `./lab.sh stop-backend 3`: you get **502**, and `./lab.sh logs` shows `no live upstreams`.
5. `./lab.sh start-backend 1` and `start-backend 2`, wait 6 seconds, curl again.
6. Edit `nginx.conf.tpl`: add `least_conn;` or `weight=3` in the upstream, run `./lab.sh up` (it reloads), and compare the distribution.
7. Break the config on purpose (delete a `;`) and run `./lab.sh up` to see `nginx -t` catch it.
8. Watch real packets: `sudo tcpdump -i lo -nn 'tcp port 8080 or tcp port 9001'`.

---

## 6. What I Learned From This Build

- **A start-up race can look like a real failure.** My first full run failed two checks: one request errored and the backup server was skipped later. Cause: Nginx started before all backends were listening, so it marked servers as failed. A `backup` entry has the defaults `max_fails=1` and `fail_timeout=10s`, so **one** early failure kept it out for 10 seconds. Fix: wait until every backend answers `/health` before starting Nginx. After that the demo passed three runs in a row.
- **Failed servers are not retried instantly.** `fail_timeout` decides how long a failed server stays out, so tests that restart a backend must wait.
- **Failover can be invisible to users.** With `proxy_next_upstream`, stopping one backend produced **zero** failed requests, because Nginx retried on the next server.
- **Test the failure, not only the success.** Most of the value of the lab is in the "break it" steps.
- **Port conflicts are common.** The error log showed `bind() ... failed (98: Address already in use)` until I stopped the other program.

---

## 7. Errors Faced Today
- Example: `nginx: [emerg] bind() to 0.0.0.0:8080 failed (98: Address already in use)`
- Cause: another program was already listening on port 8080
- Fix: find it with `ss -tulpn | grep 8080`, stop it (or change `HTTP_PORT`), start again

Full story: `troubleshooting/error-01.md`

---

## 8. Quick Q&A (for interviews)

**Q: Tell me about a project you built.**
"I built a reverse proxy and load balancer lab. Nginx listens on HTTP and HTTPS and shares requests between two Python backends, with a third backend as a backup. One script, `lab.sh`, starts everything, runs automatic checks (balancing, HTTPS, forwarded headers, logging), then stops backends one by one to prove failover: with one backend down users see no errors, with two down the backup answers, and with all down Nginx returns 502 and the error log shows why. It exits with 0 only if every check passes."

**Q: What went wrong while building it?**
"My first run failed two checks. Nginx started before all backends were ready, so it marked servers as failed, and the backup had the default `max_fails=1` and `fail_timeout=10s`, so it stayed out for 10 seconds. I fixed it by waiting until every backend answered its health URL before starting Nginx."

**Q: How does failover work in your setup?**
"Each server has `max_fails=2 fail_timeout=5s`, so after two failures it is skipped for 5 seconds. `proxy_next_upstream` retries a failed request on the next server, so users don't see the failure. The `backup` server is used only when all normal servers are unavailable."

**Q: How do you know which backend answered?**
"The backend puts its name in the response, and the Nginx access log has a custom format with `upstream=$upstream_addr`."

**Q: Why forward `X-Forwarded-For`?**
"Behind a proxy the app only sees Nginx's IP. This header carries the real client IP, which is needed for logs, rate limits and security rules."

**Q: How would you do this in production on AWS?**
"Use an Application Load Balancer with active health checks across instances in several Availability Zones, a real certificate from ACM, and Auto Scaling. Nginx stays useful as an ingress or a reverse proxy on each server."

**Q: How would you extend it?**
"Run it with Docker Compose, deploy it on EC2 with Terraform, add active health checks, and send Nginx metrics to Prometheus and Grafana."

---

## 9. Week 2 Recap (one line per day)

| Day | Topic | One-line takeaway |
|---|---|---|
| Mon | TCP/IP, subnets, CIDR | usable hosts = 2^(32 - prefix) - 2; same subnet talks directly, else via the gateway |
| Tue | DNS | cache, `/etc/hosts`, resolver, root, TLD, authoritative; `dig` ignores the hosts file |
| Wed | HTTP, HTTPS, TLS, curl | 4xx is my request, 5xx is the server; DNS, TCP, TLS, then HTTP |
| Thu | Nginx | `proxy_pass`, `upstream`, round robin, `backup`, `nginx -t` then `reload` |
| Fri | Firewalls and VPN | Security Groups and rules decide who can reach which port |
| Sat | Network debugging | refused = nothing listening, timeout = packets dropped |
| Sun | Mega project | prove it works, and prove it fails safely |

---

## 10. Summary in 3 lines
1. Users hit Nginx, which shares requests between backends, retries failures and uses a backup server when needed.
2. `lab.sh` automates the lifecycle (up, test, failover, down) and returns an exit code, and a readiness wait prevents start-up races.
3. A good project has a diagram, automatic tests including failure cases, an error log of what really went wrong, and a clear README.