# Networking for DevOps | Week 2 - Wednesday: HTTP, HTTPS, TLS and curl
## Today's Goal
Understand how web requests work (HTTP, status codes, headers), how HTTPS and TLS certificates protect them, and how to test and debug a web server with `curl` and `openssl`.

## Plan (checklist)
- [x] Learn the concept (request and response, methods, status codes, TLS handshake)
- [x] Hands-on lab: `curl -v`, redirects, timing, certificate check, my own web server
- [x] Write `httpcheck.sh`, a website health checker
- [x] Write notes in `documentation/`
- [x] Log one error in `troubleshooting/`
- [x] Commit and push with a clear message

## What I Did
- Learned the structure of HTTP requests and responses, the methods (GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS) and the main headers.
- Learned status codes by group, and what 401 vs 403 and 502 vs 503 vs 504 mean behind a proxy.
- Learned HTTP/1.1, HTTP/2 and HTTP/3, and how HTTPS adds TLS (encryption, integrity, identity).
- Learned the order on the wire: DNS, TCP handshake, TLS handshake, HTTP request.
- Practised `curl` (`-I`, `-i`, `-v`, `-L`, `-f`, `-o`, `-X`, `-H`, `-d`, `--resolve`, `-w` timing) and its exit codes (6, 7, 22, 28, 35, 60).
- Checked a certificate's dates and issuer with `openssl s_client`.
- Wrote `httpcheck.sh`, which shows the status code, redirects, a timing breakdown (DNS, connect, TLS, first byte, total) and the certificate expiry, with a clear failure reason for each curl error.

## Scripts in this folder
| File | What it does |
|---|---|
| [`httpcheck.sh`](httpcheck.sh) | `./httpcheck.sh https://example.com` prints status, redirects, timings and certificate days left. Exit 0 for 2xx/3xx, 1 for errors, 2 for wrong usage |

## Lab Summary
```bash
curl -v https://example.com 2>&1 | head -30
curl -sIL http://github.com | grep -iE "^HTTP|^location"
curl -s -o /dev/null -w "dns:%{time_namelookup} tls:%{time_appconnect} ttfb:%{time_starttransfer} total:%{time_total}\n" https://github.com
echo | openssl s_client -connect github.com:443 -servername github.com 2>/dev/null | openssl x509 -noout -dates -issuer
python3 -m http.server 8081 &
curl -i http://localhost:8081/missing        # 404
./httpcheck.sh https://github.com
```
Result: saw the headers and status codes, followed a 301 redirect, measured each stage of a request, and read a certificate's expiry. (Add a screenshot in `documentation/images/`.)

## What I Learned
- 2xx works, 4xx is a client mistake, 5xx is a server problem; 502, 503 and 504 point at the app behind a proxy.
- `curl -w` timing shows whether DNS, TCP, TLS or the app is slow.
- "Connection refused" means nothing is listening; a timeout means something blocks it; "could not resolve" means DNS.
- Certificates expire and must match the host name; `curl` exit code 60 is a certificate problem.
- Test a server before DNS changes with `curl --resolve` or the `Host` header.

## Errors Faced
- `curl: (7) Connection refused` (the test server was not running): see [`troubleshooting/error-01.md`](troubleshooting/error-01.md)

## Notes
Full notes: [`documentation/notes.md`](documentation/notes.md)

## Tomorrow
Day 4: Nginx as a web server and reverse proxy, and load balancing (upstream, `proxy_pass`, health and round robin).