# Notes: Day 3 - HTTP, HTTPS, TLS and curl

**Week 2 | Wednesday** | Topic: how web requests work, status codes, certificates, and testing with curl

---

## 1. What is HTTP?
- **HTTP** (HyperText Transfer Protocol) is how browsers, apps and APIs talk to web servers.
- It works as **request -> response**: the client asks, the server answers.
- Runs on top of TCP. Default ports: **80** (HTTP) and **443** (HTTPS).
- HTTP is **stateless**: the server does not remember earlier requests (cookies and tokens add memory).

### Parts of a URL
```
https://app.example.com:8443/api/users?id=5#top
 |        |             |    |          |    |
scheme   host          port path      query fragment
```

---

## 2. Request and Response

**Request (client -> server)**
```
GET /api/users HTTP/1.1          <- method, path, version
Host: app.example.com            <- headers
User-Agent: curl/8.5.0
Accept: application/json
                                  <- empty line
(body, only for POST/PUT)
```

**Response (server -> client)**
```
HTTP/1.1 200 OK                  <- version, status code, reason
Content-Type: application/json   <- headers
Content-Length: 42
                                  <- empty line
{"users": [...]}                 <- body
```

---

## 3. HTTP Methods

| Method | Use | Has body? | Safe to repeat? |
|---|---|---|---|
| **GET** | Read data | No | Yes |
| **POST** | Create / send data | Yes | No |
| **PUT** | Replace a whole item | Yes | Yes |
| **PATCH** | Change part of an item | Yes | Usually |
| **DELETE** | Remove an item | No | Yes |
| **HEAD** | Like GET, headers only | No | Yes |
| **OPTIONS** | What is allowed here? (CORS checks) | No | Yes |

---

## 4. Status Codes (very important)

| Group | Meaning |
|---|---|
| **1xx** | Information |
| **2xx** | Success |
| **3xx** | Redirect |
| **4xx** | Client error (my request is wrong) |
| **5xx** | Server error (the server failed) |

| Code | Name | Meaning in practice |
|---|---|---|
| **200** | OK | Worked |
| **201** | Created | New item created (POST) |
| **204** | No Content | Worked, nothing to return |
| **301** | Moved Permanently | New URL forever (browsers cache it) |
| **302** | Found | Temporary redirect |
| **304** | Not Modified | Use your cached copy |
| **400** | Bad Request | Broken request or JSON |
| **401** | Unauthorized | Not logged in / bad credentials |
| **403** | Forbidden | Logged in, but not allowed |
| **404** | Not Found | URL or resource does not exist |
| **405** | Method Not Allowed | Wrong method (GET on a POST-only URL) |
| **429** | Too Many Requests | Rate limited |
| **500** | Internal Server Error | The app crashed or has a bug |
| **502** | Bad Gateway | Proxy/load balancer got a **bad or no answer from the app behind it** |
| **503** | Service Unavailable | Server overloaded or in maintenance |
| **504** | Gateway Timeout | Proxy waited too long for the app |

**DevOps meaning of 5xx behind Nginx or a load balancer**
- **502:** the app is down, crashed, or on the wrong port. Check the app and `proxy_pass`.
- **503:** no healthy backends, or overload.
- **504:** the app is too slow, so check timeouts and app performance.
- **401 vs 403:** 401 = "who are you?", 403 = "I know you, but no."

---

## 5. Important Headers

| Header | Direction | Purpose |
|---|---|---|
| `Host` | Request | Which website I want (many sites share one IP) |
| `User-Agent` | Request | Client name |
| `Accept` | Request | Formats I accept (`application/json`) |
| `Authorization` | Request | Credentials (`Bearer <token>`) |
| `Content-Type` | Both | Format of the body |
| `Content-Length` | Both | Size of the body |
| `Cookie` / `Set-Cookie` | Request / Response | Session data |
| `Cache-Control` | Response | How long to cache |
| `Location` | Response | Where to go on a 301/302 |
| `Server` | Response | Server software |
| `X-Forwarded-For` | Request | Real client IP behind a proxy or load balancer |
| `Strict-Transport-Security` | Response | Force HTTPS (HSTS) |

---

## 6. HTTP Versions

| Version | Key idea |
|---|---|
| **HTTP/1.1** | Text based, keep-alive connections (still very common) |
| **HTTP/2** | Binary, many requests on one connection (multiplexing), used over TLS |
| **HTTP/3** | Runs on QUIC over **UDP**, faster on bad networks |

---

## 7. HTTPS and TLS

**HTTPS = HTTP + TLS (encryption).** It gives three things:
1. **Encryption:** nobody on the network can read the data.
2. **Integrity:** data can't be changed unnoticed.
3. **Authentication:** I'm really talking to the real server (certificate).

> "SSL" is the old name. Today we use **TLS 1.2 or 1.3**. SSL and TLS 1.0/1.1 are insecure.

### TLS handshake (simple)
```
Client  -- "Hello, I support TLS 1.3, here are my ciphers" -->  Server
Client  <-- "Hello, here is my CERTIFICATE" ------------------  Server
Client checks the certificate (trusted CA? right name? not expired?)
Client and server agree on a secret key
Both  <== encrypted HTTP traffic ==>
```
Order on the wire: **DNS -> TCP handshake -> TLS handshake -> HTTP request**.

### Certificates
- A certificate says "this public key belongs to `example.com`", signed by a **CA** (Certificate Authority) such as Let's Encrypt, DigiCert or AWS ACM.
- Chain of trust: **root CA -> intermediate CA -> my certificate**. The browser trusts the root.
- The name must match the host (checked against **CN / SAN**).
- It **expires**. Let's Encrypt certificates last 90 days, so renew automatically (certbot, ACM).
- A **self-signed** certificate is not trusted by default (fine for labs, not for production).

Common certificate problems
| Problem | Message |
|---|---|
| Expired | `certificate has expired` |
| Wrong name | `no alternative certificate subject name matches` |
| Not trusted / self-signed | `self-signed certificate`, `unable to get local issuer certificate` |
| Missing intermediate | works in browser, fails in `curl` or an app |

---

## 8. curl Commands

```bash
curl https://example.com                    # GET, show body
curl -I https://example.com                 # headers only (HEAD request)
curl -i https://example.com                 # headers + body
curl -v https://example.com                 # verbose: DNS, TCP, TLS and headers
curl -s https://example.com                 # silent (no progress bar)
curl -o page.html https://example.com       # save to a file
curl -O https://example.com/file.zip        # save with the remote name
curl -L http://example.com                  # follow redirects
curl -f https://example.com/missing         # fail with exit code 22 on 4xx/5xx (good in scripts)
curl --max-time 10 --connect-timeout 5 URL  # timeouts
curl --retry 3 URL                          # retry on failure
curl -k https://localhost:8443              # skip certificate check (tests only!)
```

**Send data**
```bash
curl -X POST https://api.example.com/users \
     -H "Content-Type: application/json" \
     -d '{"name":"shubham"}'                # POST JSON
curl -H "Authorization: Bearer TOKEN" URL   # token auth
curl -u user:password URL                   # basic auth
curl -X DELETE URL/users/5
```

**Test a server before DNS or a load balancer is ready**
```bash
curl -H "Host: example.com" http://203.0.113.10/        # send the Host header to an IP
curl --resolve example.com:443:203.0.113.10 https://example.com   # pretend DNS points to that IP
```

**Print only the status code**
```bash
curl -s -o /dev/null -w "%{http_code}\n" https://example.com
```

**Timing breakdown**
```bash
curl -s -o /dev/null -w "dns: %{time_namelookup}  connect: %{time_connect}  tls: %{time_appconnect}  first-byte: %{time_starttransfer}  total: %{time_total}\n" https://example.com
```
| Timing | Slow means |
|---|---|
| `time_namelookup` | DNS is slow |
| `time_connect` | Network or firewall is slow |
| `time_appconnect` | TLS handshake is slow |
| `time_starttransfer` | The **app** is slow (waiting for the first byte) |
| `time_total` | Everything including download |

### Common curl exit codes
| Code | Meaning | Check |
|---|---|---|
| 6 | Could not resolve host | DNS (Day 2) |
| 7 | Failed to connect / refused | Service running? port? firewall? |
| 22 | HTTP error with `-f` | Status code 4xx/5xx |
| 28 | Timeout | Slow server or blocked |
| 35 | TLS handshake error | TLS version / cipher / port is not HTTPS |
| 52 | Empty reply | App closed the connection |
| 56 | Connection reset | App or proxy crashed |
| 60 | Certificate problem | Expired, wrong name or untrusted |

---

## 9. Check a Certificate with openssl

```bash
echo | openssl s_client -connect example.com:443 -servername example.com 2>/dev/null | openssl x509 -noout -dates -subject -issuer
# notBefore=...   notAfter=...   subject=CN=example.com   issuer=...

echo | openssl s_client -connect example.com:443 -servername example.com 2>/dev/null | openssl x509 -noout -ext subjectAltName
```
`-servername` sends the site name (SNI), which many servers need to give the right certificate.

---

## 10. Troubleshooting Flow (builds on Day 1 and 2)

```
1. DNS      dig +short example.com            (or curl exit code 6)
2. Network  ping IP / curl exit code 7        is the IP reachable?
3. Port     nc -vz example.com 443            is the port open?   (or: curl -v)
4. TLS      curl -v / openssl s_client        certificate valid?
5. HTTP     curl -I URL                       what status code?
6. App      logs: journalctl -u app, /var/log/nginx/error.log
```
```bash
nc -vz example.com 443            # port test (install: sudo apt install netcat-openbsd)
sudo ss -tulpn | grep :80         # is something listening locally?
```

---

## 11. Lab (Hands-on)

**Goal:** read real HTTP responses, follow redirects, time a request, and check a certificate.

```bash
# 1. look at a real request and response
curl -v https://example.com 2>&1 | head -30
curl -I https://github.com

# 2. status codes
curl -s -o /dev/null -w "%{http_code}\n" https://example.com
curl -s -o /dev/null -w "%{http_code}\n" https://example.com/nopage     # 404

# 3. redirects
curl -I http://github.com                  # 301 to https
curl -sIL http://github.com | grep -iE "^HTTP|^location"

# 4. timing
curl -s -o /dev/null -w "dns:%{time_namelookup} connect:%{time_connect} tls:%{time_appconnect} ttfb:%{time_starttransfer} total:%{time_total}\n" https://github.com

# 5. certificate
echo | openssl s_client -connect github.com:443 -servername github.com 2>/dev/null | openssl x509 -noout -dates -issuer

# 6. my own web server
mkdir -p ~/web && echo "<h1>Hello DevOps</h1>" > ~/web/index.html
cd ~/web && python3 -m http.server 8081 &
curl -i http://localhost:8081/
curl -i http://localhost:8081/missing       # 404
kill %1
curl http://localhost:8081/                 # curl: (7) Failed to connect  (server stopped)

# 7. my script
./httpcheck.sh https://github.com
./httpcheck.sh http://github.com            # shows the redirect
```

Result: (write what happened, add a screenshot)

---

## 12. Errors Faced Today
- Example: `curl: (7) Failed to connect to localhost port 8081: Connection refused`
- Cause: nothing was listening on that port (the server was stopped or on another port)
- Fix: check with `ss -tulpn`, start the service, and test again

Full story: `troubleshooting/error-01.md`

---

## 13. Quick Q&A (for interviews)

**Q: What happens when you type a URL in the browser?**
1) The browser checks its cache, then DNS gives the IP. 2) A TCP connection opens to port 443 (3-way handshake). 3) The TLS handshake checks the certificate and sets up encryption. 4) The browser sends an HTTP request (`GET /` with a `Host` header). 5) The server (often behind a load balancer or reverse proxy) runs the app and returns a status code, headers and body. 6) The browser renders the page and loads more resources.

**Q: HTTP vs HTTPS?**
HTTPS is HTTP inside TLS, so the traffic is encrypted, can't be changed unnoticed, and the server's identity is checked with a certificate. HTTPS uses port 443.

**Q: 401 vs 403?**
401 means not authenticated (missing or wrong login). 403 means authenticated but not allowed.

**Q: 502 vs 503 vs 504?**
502: the proxy got a bad or no response from the app (app down or wrong port). 503: service unavailable (overloaded, no healthy backends). 504: the proxy timed out waiting for the app.

**Q: 301 vs 302?**
301 is a permanent redirect (browsers and search engines cache it). 302 is temporary.

**Q: GET vs POST?**
GET reads data and can be repeated safely, with parameters in the URL. POST sends data in the body to create or change something.

**Q: What is a TLS handshake?**
The client and server agree on a TLS version and ciphers, the server shows its certificate, the client checks it, and both create a shared secret key for the session.

**Q: A site works in the browser but `curl` says certificate error 60. Why?**
Often a missing intermediate certificate in the server's chain, which browsers can fetch but curl can't. It can also be an expired certificate or the wrong name.

**Q: How do you test a server before changing DNS?**
`curl --resolve example.com:443:<new-ip> https://example.com` or `curl -H "Host: example.com" http://<new-ip>/`.

**Q: How do you find which part of a request is slow?**
`curl -w` with `time_namelookup`, `time_connect`, `time_appconnect` and `time_starttransfer` shows whether DNS, TCP, TLS or the app is the slow part.

**Q: What does `curl -f` do in a script?**
It makes curl exit with code 22 for HTTP errors (4xx/5xx), so the script can detect a failed request.

---

## 14. Summary in 3 lines
1. HTTP is request and response (method, headers, status code); 2xx works, 4xx is my mistake, 5xx is the server's, and 502/503/504 point at the app behind a proxy.
2. HTTPS = HTTP + TLS: DNS, then TCP, then TLS (certificate checked), then HTTP; certificates expire and must match the name.
3. `curl -I`, `curl -v`, `curl -w` timing and `openssl s_client` find the failing layer: DNS, connect, TLS, HTTP or the app.