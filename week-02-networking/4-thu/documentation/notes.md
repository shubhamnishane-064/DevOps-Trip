# Notes: Day 4 - Nginx: Web Server, Reverse Proxy and Load Balancer

**Week 2 | Thursday** | Topic: serving websites, sitting in front of apps, sharing traffic between servers

---

## 1. What is Nginx?
- **Nginx** (say "engine-x") is a fast, light web server. It can do four jobs:

| Job | What it means |
|---|---|
| **Web server** | Serves files (HTML, images, CSS) |
| **Reverse proxy** | Sits in front of an app and passes requests to it |
| **Load balancer** | Shares requests between several app servers |
| **TLS termination** | Handles HTTPS so the app can speak plain HTTP behind it |

- It handles thousands of connections with little memory (event-driven design).
- Apache is the older alternative. Nginx is more common as a reverse proxy.

---

## 2. Forward Proxy vs Reverse Proxy

```
FORWARD proxy (hides the CLIENT):
  Me --> [proxy] --> Internet
  Used by companies to control and filter users' traffic.

REVERSE proxy (hides the SERVER):
  Internet --> [Nginx] --> App server(s)
  Used to protect, speed up and balance the apps.
```

**Why put Nginx in front of an app?**
- One public entry point (port 80/443), apps stay private
- HTTPS in one place
- Load balancing and failover
- Caching, compression, rate limiting
- Hide internal ports and server details

---

## 3. Install and File Locations (Ubuntu / Debian)

```bash
sudo apt install nginx -y
sudo systemctl enable --now nginx
curl -I http://localhost            # HTTP/1.1 200 OK, Server: nginx
```

| Path | What it is |
|---|---|
| `/etc/nginx/nginx.conf` | Main config |
| `/etc/nginx/conf.d/*.conf` | My site configs (loaded automatically) |
| `/etc/nginx/sites-available/` + `sites-enabled/` | Debian style: write in `available`, link into `enabled` |
| `/var/www/html` | Default website folder |
| `/var/log/nginx/access.log` | Every request |
| `/var/log/nginx/error.log` | Errors (read this first) |

```bash
sudo nginx -t                        # test the config (ALWAYS before reload)
sudo nginx -T                        # test and print the full config
sudo systemctl reload nginx          # apply changes with no downtime
sudo systemctl restart nginx         # full restart (drops connections)
sudo ln -s /etc/nginx/sites-available/mysite /etc/nginx/sites-enabled/    # enable a site
```
**reload vs restart:** `reload` starts new workers with the new config and finishes old requests. If the new config is broken, the old one keeps running. Prefer `reload`.

---

## 4. Config Structure

```
main (user, worker_processes, pid)
events { worker_connections }
http {
    upstream myapp { server ...; }        <- group of backends
    server {                              <- one website (virtual host)
        listen 80;
        server_name example.com;
        location / { ... }                <- rules per URL
        location /api/ { ... }
    }
}
```
Every directive ends with **`;`**. A missing `;` is the most common error.

### `location` matching (simple version)
| Form | Meaning | Priority |
|---|---|---|
| `location = /health` | Exact match | Highest |
| `location ^~ /static/` | Prefix, skip regex checks | High |
| `location ~ \.php$` | Regex (case sensitive); `~*` is case-insensitive | Medium |
| `location /` | Prefix, longest wins | Lowest (the default catch-all) |

---

## 5. Nginx as a Web Server

```nginx
server {
    listen 80;
    server_name mysite.local;
    root /var/www/mysite;
    index index.html;

    location / {
        try_files $uri $uri/ =404;      # file, then folder, else 404
    }
    location /private/ { deny all; }    # 403
}
```
- **Virtual hosts:** many sites on one server. Nginx picks the `server` block by the `Host` header (`server_name`).
- `return 301 https://$host$request_uri;` redirects HTTP to HTTPS.
- `root` adds the URL path to the folder, while `alias` replaces the location path.
- Permissions: the `www-data` user must be able to read the files, or you get **403**.

---

## 6. Nginx as a Reverse Proxy

```nginx
server {
    listen 80;
    location / {
        proxy_pass http://127.0.0.1:9001;                       # the real app

        proxy_set_header Host $host;                            # keep the original Host
        proxy_set_header X-Real-IP $remote_addr;                # real client IP
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;             # http or https

        proxy_connect_timeout 5s;
        proxy_read_timeout 30s;
    }
}
```
- Without `X-Forwarded-For`, the app sees only Nginx's IP (`127.0.0.1`) instead of the user's IP.
- **Slash gotcha:** `proxy_pass http://app;` passes the full URL. `proxy_pass http://app/;` (with a trailing slash) replaces the matched location prefix. Know which one you want.
- WebSockets need `proxy_http_version 1.1;` and the `Upgrade` and `Connection` headers.

---

## 7. Nginx as a Load Balancer

```nginx
upstream myapp {
    server 127.0.0.1:9001 weight=1 max_fails=2 fail_timeout=10s;
    server 127.0.0.1:9002 weight=1 max_fails=2 fail_timeout=10s;
    server 127.0.0.1:9003 backup;           # used only when the others are down
}
server {
    listen 80;
    location / {
        proxy_pass http://myapp;            # the name of the upstream block
        proxy_next_upstream error timeout http_502 http_503;   # retry on the next server
    }
}
```

### Balancing methods
| Method | Config | How it picks |
|---|---|---|
| **Round robin** | (default) | 1, 2, 1, 2 ... in turn |
| **Weighted** | `weight=3` | Server with weight 3 gets 3 times more |
| **Least connections** | `least_conn;` | Server with the fewest active connections |
| **IP hash** | `ip_hash;` | Same client IP goes to the same server (sticky) |
| **Hash** | `hash $request_uri;` | By any key (good for caches) |

### Server options
| Option | Meaning |
|---|---|
| `weight=N` | Share of traffic |
| `max_fails=N fail_timeout=T` | After N failures, skip the server for T seconds |
| `backup` | Standby, used only when all normal servers fail |
| `down` | Take the server out on purpose (maintenance) |

### Health checks
- Open-source Nginx has **passive** health checks only: it notices failures from real traffic (`max_fails`).
- **Active** checks (Nginx pings `/health` regularly) need Nginx Plus. Cloud load balancers (AWS ALB) include active checks.
- **Layer 7** (HTTP, what `proxy_pass` does) vs **Layer 4** (raw TCP, the `stream` module).
- Sessions stored on one server break with round robin. Fix with `ip_hash`, a shared session store (Redis), or sticky cookies at the load balancer.

---

## 8. HTTPS (TLS termination)

```nginx
server { listen 80; server_name myapp.example.com; return 301 https://$host$request_uri; }

server {
    listen 443 ssl;
    server_name myapp.example.com;
    ssl_certificate     /etc/letsencrypt/live/myapp.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/myapp.example.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    location / { proxy_pass http://myapp; ...proxy_set_header lines... }
}
```
Free certificates: `sudo apt install certbot python3-certbot-nginx` then `sudo certbot --nginx -d myapp.example.com` (renews automatically).

---

## 9. Reading Nginx Logs

```bash
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```
Access log line:
```
203.0.113.5 - - [25/Oct/2026:10:00:01 +0000] "GET /api HTTP/1.1" 502 157 "-" "curl/8.5.0"
 client IP         time                     request        status bytes  referrer  agent
```

### Error log messages and what they mean
| Message | Meaning | Usual fix |
|---|---|---|
| `connect() failed (111: Connection refused) while connecting to upstream` | The app is **not listening** on that port | Start the app, check the port (`ss -tulpn`) |
| `no live upstreams while connecting to upstream` | **All** backends are marked down | Fix the backends; wait for `fail_timeout` |
| `upstream timed out (110: Connection timed out)` | App too slow | **504**: tune the app or `proxy_read_timeout` |
| `upstream prematurely closed connection` | App crashed mid-request | **502**: check app logs |
| `open() ... failed (13: Permission denied)` | Nginx user can't read the file | **403**: fix permissions (`chmod`/`chown`) |
| `open() ... failed (2: No such file or directory)` | File missing | **404**: check `root` path |
| `bind() to 0.0.0.0:80 failed (98: Address already in use)` | Another program uses port 80 | `sudo ss -tulpn \| grep :80` |
| `invalid number of arguments in "proxy_pass" directive` | Syntax error (often a missing `;`) | `nginx -t` shows the line |

---

## 10. What I Tested (real results from my lab run)

I ran real Nginx (round robin, two backends on ports 9001 and 9002, plus a backup on 9003) and sent requests with `lb_test.sh`. Your numbers will look similar.

| Test | Result |
|---|---|
| 20 requests, both backends up | backend-1: 10, backend-2: 10 (50% / 50%) |
| Stop backend-1 | 10 of 10 requests OK, all served by backend-2 (`proxy_next_upstream` retried silently) |
| Stop both backends | **502 Bad Gateway** |
| Error log then showed | `connect() failed (111: Connection refused)` and then `no live upstreams` |
| Start the backup (9003) right away | Still 502, because Nginx had marked it failed for `fail_timeout` (10 s) |
| Wait 12 s | 5 of 5 OK, answered by the backup |
| Start backend-1 and backend-2 again | Back to 50% / 50% |
| Remove `;` after `proxy_pass` | `nginx -t`: `[emerg] invalid number of arguments in "proxy_pass" directive ... :10` |

Lesson: failure handling is not instant. `max_fails` and `fail_timeout` decide how long a failed server stays out.

---

## 11. Lab (Hands-on)

**Goal:** build a reverse proxy and a load balancer with two backends and watch failover.

```bash
# 0. install
sudo apt install nginx curl python3 -y

# 1. start two test backends (files in this folder)
./backends.sh start
./backends.sh status                       # both UP
curl http://127.0.0.1:9001/                # Hello from backend-1
curl http://127.0.0.1:9002/                # Hello from backend-2

# 2. reverse proxy to ONE backend
sudo cp configs/reverse-proxy.conf /etc/nginx/conf.d/
sudo nginx -t && sudo systemctl reload nginx
curl http://localhost:8080/                # answered by backend-1 through Nginx
sudo rm /etc/nginx/conf.d/reverse-proxy.conf

# 3. load balancer
sudo cp configs/load-balancer.conf /etc/nginx/conf.d/
sudo nginx -t && sudo systemctl reload nginx
./lb_test.sh http://localhost:8080/ 20     # about 50% / 50%

# 4. failover
./backends.sh stop-one 9001
./lb_test.sh http://localhost:8080/ 10     # all go to backend-2, no errors
./backends.sh stop-one 9002
curl -i http://localhost:8080/             # 502 Bad Gateway
sudo tail -5 /var/log/nginx/error.log      # read the reason

# 5. recover
./backends.sh start
sleep 12
./lb_test.sh http://localhost:8080/ 10

# 6. try other methods: add "least_conn;" or "weight=3" in the upstream block, reload, repeat step 3
# 7. break it on purpose: remove one ";" and run: sudo nginx -t

# clean up
./backends.sh stop
sudo rm /etc/nginx/conf.d/load-balancer.conf && sudo systemctl reload nginx
```
Port 8080 in the configs avoids a clash with the default site on port 80. The same Nginx on a Docker or EC2 host works the same way.

Result: (write what happened, add a screenshot)

---

## 12. Errors Faced Today
- Example: `502 Bad Gateway` from Nginx
- Cause: no backend was listening, so `error.log` showed `connect() failed (111: Connection refused)`
- Fix: start the backend, confirm the port with `ss -tulpn`, and reload Nginx

Full story: `troubleshooting/error-01.md`

---

## 13. Quick Q&A (for interviews)

**Q: Forward proxy vs reverse proxy?**
A forward proxy sits in front of clients and hides them from the internet. A reverse proxy sits in front of servers and hides them from clients. Nginx is usually a reverse proxy.

**Q: What does a reverse proxy give you?**
One entry point, HTTPS termination, load balancing, caching, compression, rate limiting, and hidden internal servers.

**Q: Which load balancing methods does Nginx support?**
Round robin (default), weighted, least connections, IP hash and generic hash.

**Q: How does Nginx know a backend is down?**
Open-source Nginx uses passive checks: after `max_fails` failures within `fail_timeout`, it skips that server for `fail_timeout` seconds. Active health checks need Nginx Plus or a cloud load balancer.

**Q: 502 vs 503 vs 504?**
502: bad or no response from the backend (down, crashed, wrong port). 503: service unavailable (overloaded or no healthy servers). 504: the backend took too long.

**Q: A user gets 502. What do you check?**
`curl -I` to confirm, then `sudo tail /var/log/nginx/error.log` for the reason, `ss -tulpn` to see if the app is listening, `systemctl status app` and the app's logs, then `proxy_pass` for a wrong port.

**Q: `reload` vs `restart`?**
`reload` applies the config without dropping connections and keeps the old config if the new one is invalid. `restart` stops and starts the service.

**Q: Why use `X-Forwarded-For`?**
Behind a proxy the app sees only the proxy's IP. This header carries the real client IP chain.

**Q: How do you keep a user on the same server?**
`ip_hash`, sticky cookies (at the load balancer), or store sessions in a shared place such as Redis so any server can handle the user.

**Q: Nginx vs AWS ALB?**
Both are layer 7 load balancers. ALB is managed (no servers to run, active health checks, auto scaling integration). Nginx is self-managed and flexible, and often used inside containers or Kubernetes (ingress).

**Q: How do you test an Nginx change safely?**
`sudo nginx -t`, then `sudo systemctl reload nginx`, then `curl -I` to confirm, and watch `error.log`.

---

## 14. Summary in 3 lines
1. Nginx serves files, proxies requests to apps (`proxy_pass` + forwarded headers), and balances load with an `upstream` block (round robin, weight, least_conn, ip_hash, backup).
2. Always `nginx -t` then `reload`; read `/var/log/nginx/error.log`, where `Connection refused` means the app is down and `no live upstreams` means every backend is marked failed.
3. 502 = bad answer from the app, 503 = unavailable, 504 = timeout; `max_fails` and `fail_timeout` decide how fast a failed server returns.