# Networking for DevOps | Week 2 - Saturday: Network debugging (ss, nc, traceroute, tcpdump)

## Today's Goal
Learn to find out *why* a connection fails: test one layer at a time, tell open, closed and filtered ports apart, and prove it with `ss`, `nc`, `traceroute`/`mtr` and `tcpdump`.

## Plan (checklist)
- [x] Learn the bottom-up debugging method
- [x] Learn `ss`, `nc`, `ping`, `traceroute`, `mtr`, `tcpdump`
- [x] Create open, closed and filtered ports and compare the results
- [x] Write `portcheck.sh`
- [x] Write notes in `documentation/`
- [x] Log one error in `troubleshooting/`
- [x] Commit and push with a clear message

## What I Did
- Learned the debugging order: IP and route, DNS, path, port, firewall, application.
- Learned that **refused = reachable but nothing listening (RST)** and **timeout = packets dropped**, and why AWS Security Groups give timeouts.
- Used `ss -tulpn` to see what listens, and learned that `127.0.0.1` vs `0.0.0.0` decides who can connect.
- Tested ports with `nc -vz`, and used `traceroute` / `mtr` to follow the path and read `* * *` and Loss%.
- Captured real packets with `tcpdump` and read the flags: a normal handshake (`S`, `S.`, `.`), a refused port (`R.`), and a dropped connection (the same `S` repeated, no `S.`).
- Wrote `portcheck.sh`, which reports a port as OPEN, CLOSED or FILTERED and exits with a code for scripts.
- Created the three situations with `iptables` DROP and REJECT rules, then removed them.
- Compared the same checks with the AWS path: route table, Security Group, NACL, OS firewall, app.

## Scripts in this folder
| File | What it does |
|---|---|
| [`portcheck.sh`](portcheck.sh) | `./portcheck.sh <host> <port> [port ...]` prints OPEN, CLOSED or FILTERED with the time taken. Exit 0 only if all ports are open |

## Lab Summary
```bash
python3 -m http.server 9101 &
./portcheck.sh 127.0.0.1 9101 9102             # OPEN, CLOSED
sudo tcpdump -i lo -nn -c 10 'tcp port 9101'   # handshake
sudo iptables -A INPUT -p tcp --dport 9101 -j DROP
./portcheck.sh 127.0.0.1 9101                  # FILTERED (curl exit 28, SYN repeated)
sudo iptables -D INPUT -p tcp --dport 9101 -j DROP
```
Result: the same port showed as open, closed and filtered depending on the firewall rule, and tcpdump showed exactly where packets stopped. (Add screenshots in `documentation/images/`.)

## What I Learned
- A **DROP** looks like a timeout, a **REJECT** looks like "refused".
- `ss` showing `0.0.0.0:PORT` and still a timeout means a firewall, Security Group or route is blocking.
- Ping can fail while the service works, because ICMP is often blocked.
- A `* * *` hop in traceroute is not always a failure.
- Many `CLOSE-WAIT` connections point to an application that does not close its sockets.

## Errors Faced
- `curl: (28) Connection timed out` although the service was running (firewall DROP rule): see [`troubleshooting/error-01.md`](troubleshooting/error-01.md)

## Notes
Full notes: [`documentation/notes.md`](documentation/notes.md)

## Tomorrow
Day 7 (Sunday): Week 2 mega project, an Nginx reverse proxy and load balancer lab with two backends (from Day 4), tested and documented.