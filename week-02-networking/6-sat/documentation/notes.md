# Notes: Day 6 - Network Debugging (ss, tcpdump, traceroute, nc)

**Week 2 | Saturday** | Topic: find out WHY a connection fails, layer by layer

---

## 1. The Big Idea
When "I can't reach the server", don't guess. Test **one layer at a time**, from the bottom up, and stop at the first step that fails. That step tells you where the problem is.

```
1. My machine   : do I have an IP, a route, a gateway?        (ip a, ip route)
2. Name         : does the name resolve to an IP?             (dig, getent hosts)
3. Path         : can packets reach that IP?                  (ping, traceroute, mtr)
4. Port         : is the port open, closed or filtered?       (nc, portcheck.sh, curl -v)
5. Firewall     : is a firewall or Security Group in the way? (iptables, ufw, AWS SG)
6. Application  : is the app listening, and answering?        (ss, curl -I, app logs)
```
This is the same method from Days 1 to 4, now with the tools to prove each step.

---

## 2. Open, Closed or Filtered? (the most useful idea today)

| What I see | What it means | Where to look |
|---|---|---|
| **Connects** (OPEN) | Something is listening and nothing blocks it | The problem is above TCP (app, HTTP, login) |
| **Connection refused**, answered fast (CLOSED) | The machine is reachable, but **no program listens** on that port, or a firewall sent a REJECT | Is the service running? Right port? (`ss -tulpn`) |
| **Timeout**, no answer (FILTERED) | Packets are **silently dropped** on the way: firewall, Security Group, wrong route, or the host is down | Firewall rules, Security Group, route, IP |

curl shows the same: **exit 7 = refused**, **exit 28 = timeout**.

**Real test from my lab** (same port 9101, three situations):

| Situation | `portcheck.sh` | curl exit | tcpdump showed |
|---|---|---|---|
| Server running | OPEN, 8 ms | 0 | SYN, SYN-ACK, ACK (handshake) then data |
| Nothing listening (port 9102) | CLOSED, 6 ms | 7 | SYN, then **RST** straight back |
| `iptables ... -j DROP` | FILTERED (timeout) | 28 | SYN sent **5 times**, **no reply** at all |
| `iptables ... -j REJECT` | CLOSED (refused) | 7 | SYN, then a reject message |

Remember: **a DROP looks like a timeout, a REJECT looks like "refused".**
In **AWS**, Security Groups and NACLs **drop silently**, so a timeout points to a Security Group/NACL/route, while "refused" means the traffic arrived and the app is not listening.

Other messages
| Message | Meaning |
|---|---|
| `Network is unreachable` | No route at all, often no default gateway (Day 1) |
| `No route to host` | The network answered "host unreachable" (ARP failed or router says no) |
| `Name or service not known` / `Temporary failure in name resolution` | DNS (Day 2) |
| `Connection reset by peer` | The other side closed or crashed mid-connection |

---

## 3. `ss` (who is listening, who is connected)

`ss` replaces the old `netstat`.

```bash
ss -tulpn                     # listening TCP and UDP ports + the program (needs sudo for names)
ss -tlnp                      # TCP listening only
ss -tn state established      # active TCP connections
ss -tn dst 203.0.113.10       # connections to one IP
ss -s                         # summary: totals per state
ss -tan | awk 'NR>1{print $1}' | sort | uniq -c    # count connections by state
sudo lsof -i :80              # which program uses port 80
```
Flags: `t` TCP, `u` UDP, `l` listening, `p` process, `n` numbers (no name lookup), `a` all.

**Reading the Local Address column**
| Shows | Meaning |
|---|---|
| `0.0.0.0:80` or `*:80` | Listens on **all** interfaces (reachable from other machines) |
| `127.0.0.1:5432` | Listens on **localhost only**, other machines can't connect |
| `[::]:80` | All interfaces, IPv6 |

A very common cause of "works locally, fails from outside": the app is bound to `127.0.0.1`.

**TCP states you will see**
| State | Meaning |
|---|---|
| LISTEN | Waiting for connections |
| ESTAB | Connected |
| SYN-SENT | I sent a SYN and wait for an answer (many of these = firewall dropping or server down) |
| SYN-RECV | Server got a SYN (many = possible SYN flood or slow clients) |
| TIME-WAIT | Closed recently, waiting a short time (normal, many on busy servers) |
| CLOSE-WAIT | The other side closed, **my app has not closed its end** (many = app bug / leak) |

---

## 4. `nc` (netcat): test a port in seconds

```bash
nc -vz example.com 443            # is port 443 open? (-v verbose, -z just test)
nc -vz -w 3 10.0.1.20 5432        # with a 3 second timeout
nc -vz 10.0.1.20 20-25            # a range (only on my own systems)
nc -l 9000                        # listen on port 9000 (server side of a test)
nc 192.168.1.10 9000              # connect and type text (client side)
```
Quick two-machine test: run `nc -l 9000` on machine A, run `nc <A-ip> 9000` on machine B, type a line. If it appears on A, the network path and port are fine.

My own script does the same in pure Bash and names the result:
```bash
./portcheck.sh 10.0.1.20 22 80 443
# 22   OPEN      (connected in 8 ms)
# 80   CLOSED    (refused in 6 ms ...)
# 443  FILTERED  (no answer for 3s ...)
```

---

## 5. `ping` and `traceroute` / `mtr` (is the path OK, and where does it break?)

### ping
```bash
ping -c 4 8.8.8.8                 # 4 packets
ping -c 4 -i 0.2 host             # faster interval
ping -c 5 -M do -s 1472 host      # MTU test: don't fragment, 1472 + 28 header = 1500 bytes
```
Reading the result: `time=` is the round-trip latency; **packet loss** (`% packet loss`) is the key number; `ttl=` shows roughly how many hops away (64 = Linux, 128 = Windows start values).
Important: **ping can fail while the service works**, because many firewalls and AWS Security Groups block ICMP by default. A failed ping alone does not prove the host is down. Test the real port with `nc`/`curl`.

### traceroute (path hop by hop)
```bash
traceroute -n example.com         # -n = no name lookup, faster
sudo traceroute -T -p 443 host    # use TCP to port 443 (passes firewalls that block UDP/ICMP)
tracepath example.com             # no root needed
```
```
 1  192.168.1.1     1.2 ms   1.1 ms   1.0 ms     <- my router
 2  10.20.0.1       8.5 ms   8.3 ms   8.6 ms     <- ISP
 3  * * *                                         <- no answer (often just filtered)
 4  203.0.113.10    25 ms ...                     <- destination
```
- `* * *` means "no reply from that hop". It is **not always a failure** (routers often don't answer). If **all later hops** are `* * *`, the traffic stops at the last good hop.
- A sudden jump in time at one hop (and it stays high) shows where the latency starts.

### mtr (traceroute + ping, continuously)
```bash
sudo apt install mtr-tiny -y
mtr -rwc 20 example.com           # report mode: 20 packets, wide output
```
Look at the **Loss%** column. Loss that appears at one hop and **continues to the end** is real. Loss at one middle hop only (and not after) is usually that router limiting ICMP, not a problem.

---

## 6. `tcpdump` (see the actual packets)

tcpdump shows what really crosses the network card. Use it when tools disagree or when "it should work" but doesn't.

```bash
sudo tcpdump -i any -nn -c 20                    # 20 packets on all interfaces, no name lookups
sudo tcpdump -i eth0 -nn port 80                 # one port
sudo tcpdump -i any -nn host 203.0.113.10        # one host
sudo tcpdump -i any -nn 'tcp port 443 and host 10.0.1.20'
sudo tcpdump -i any -nn udp port 53              # DNS queries
sudo tcpdump -i any -nn icmp                     # ping
sudo tcpdump -i any -nn -A port 80               # show the text (HTTP, not HTTPS)
sudo tcpdump -i any -nn -w capture.pcap port 80  # save to a file
tcpdump -nn -r capture.pcap                      # read it back (or open in Wireshark)
```
Filters: `host`, `src`, `dst`, `port`, `net 10.0.0.0/24`, `tcp`, `udp`, `icmp`, combined with `and`, `or`, `not`.

### Reading TCP flags
| Flag in output | Meaning |
|---|---|
| `[S]` | SYN: "let's connect" |
| `[S.]` | SYN-ACK: "OK, I agree" |
| `[.]` | ACK |
| `[P.]` | PUSH + ACK: data is being sent |
| `[F.]` | FIN: closing politely |
| `[R]` / `[R.]` | RST: connection refused or aborted |

### Real captures from my lab

**A. A normal request** (handshake, data, close)
```
127.0.0.1.55712 > 127.0.0.1.9101: Flags [S]      <- client: SYN
127.0.0.1.9101  > 127.0.0.1.55712: Flags [S.]    <- server: SYN-ACK
127.0.0.1.55712 > 127.0.0.1.9101: Flags [.]      <- client: ACK   (connected)
127.0.0.1.55712 > 127.0.0.1.9101: Flags [P.]     <- client sends the HTTP request
127.0.0.1.9101  > 127.0.0.1.55712: Flags [P.]    <- server sends the answer
127.0.0.1.9101  > 127.0.0.1.55712: Flags [F.]    <- server closes
```

**B. Closed port**
```
127.0.0.1.46374 > 127.0.0.1.9102: Flags [S]      <- SYN
127.0.0.1.9102  > 127.0.0.1.46374: Flags [R.]    <- RST right away = "nothing here" (connection refused)
```

**C. Firewall DROP**
```
+0.0s  127.0.0.1.59114 > 127.0.0.1.9101: Flags [S]
+1.0s  ... Flags [S]      <- same SYN again
+2.0s  ... Flags [S]
+3.1s  ... Flags [S]
+4.1s  ... Flags [S]      <- 5 SYNs, and never a SYN-ACK
```
Rule: **SYN repeated with no SYN-ACK = packets are being dropped** (firewall, Security Group, route, or the server is down). The client retries a few times, and later retries slow down.

> **Safety:** only capture on systems you own or are allowed to test, and treat `.pcap` files as sensitive (they can contain passwords or cookies on plain HTTP). HTTPS content is encrypted, so you will see handshakes and sizes but not the data.

---

## 7. Other Quick Checks

```bash
ip -br a                          # addresses
ip route                          # routes, default gateway
ip route get 10.0.1.20            # which route and source IP will be used
ip neigh                          # ARP table (IP to MAC on the local network)
ip -s link show eth0              # packet counters: look at errors and dropped
curl -v https://host              # DNS, connect, TLS and HTTP in one go (Day 3)
dig +short host                   # DNS (Day 2)
sudo iptables -S | head -20       # firewall rules (Day 5)
```
- `ip neigh` showing `FAILED` or `INCOMPLETE` for the gateway = the machine cannot find it on the local network (cable, VLAN, wrong subnet).
- Growing **errors/dropped** in `ip -s link` = a bad cable, a busy interface, or a driver problem.
- `iperf3` measures bandwidth between two machines. Low speed with low latency usually means a bandwidth or MTU problem.

---

## 8. AWS Version of the Same Checklist (preview of Week 6)

When an EC2 instance is unreachable, follow the path of the packet:

| Layer | Check |
|---|---|
| 1. Instance running? | Status checks passed |
| 2. Public IP / Elastic IP | The right IP, and it didn't change after a stop and start |
| 3. Route table + Internet Gateway | Subnet has a `0.0.0.0/0` route to the IGW (public subnet) |
| 4. **Security Group** | Inbound rule for the port from my IP (stateful) |
| 5. **Network ACL** | Allows inbound AND outbound ephemeral ports (stateless) |
| 6. OS firewall | `ufw status`, `iptables -S` |
| 7. App | `ss -tulpn` shows it listening on `0.0.0.0` |

Tools: **VPC Flow Logs** (ACCEPT or REJECT per connection) and **Reachability Analyzer** (explains the blocking component).
Handy rule: **Security Groups drop silently, so a blocked port gives a TIMEOUT**. If you get "refused", the traffic got through and the app isn't listening.

---

## 9. Lab (Hands-on)

**Goal:** create the three situations (open, closed, filtered) and recognise each with `portcheck.sh`, `curl` and `tcpdump`.
Use a test VM or WSL, and a port that is **not 22**, so you can't lock yourself out.

```bash
sudo apt install tcpdump traceroute netcat-openbsd iptables -y

# 1. start a server on port 9101
mkdir -p ~/web && echo hi > ~/web/index.html
cd ~/web && python3 -m http.server 9101 &

# 2. OPEN and CLOSED
./portcheck.sh 127.0.0.1 9101 9102
sudo ss -tlnp | grep 9101

# 3. watch the handshake (second terminal first)
sudo tcpdump -i lo -nn -c 10 'tcp port 9101'
curl -s http://127.0.0.1:9101/ > /dev/null          # first terminal

# 4. FILTERED (DROP)
sudo iptables -A INPUT -p tcp --dport 9101 -j DROP
TIMEOUT=2 ./portcheck.sh 127.0.0.1 9101              # FILTERED
curl --connect-timeout 3 http://127.0.0.1:9101/; echo $?    # 28
sudo tcpdump -l -i lo -nn 'tcp port 9101' &          # in another terminal: SYN repeats
sudo iptables -D INPUT -p tcp --dport 9101 -j DROP   # remove the rule

# 5. REJECT instead of DROP
sudo iptables -A INPUT -p tcp --dport 9101 -j REJECT
./portcheck.sh 127.0.0.1 9101                        # CLOSED (refused)
sudo iptables -D INPUT -p tcp --dport 9101 -j REJECT

# 6. traceroute and mtr
traceroute -n 8.8.8.8
mtr -rwc 10 8.8.8.8

# clean up
kill %1
sudo iptables -S INPUT                               # confirm no leftover rule
```
`iptables` rules added this way disappear at reboot. With `ufw`: `sudo ufw deny 9101/tcp` drops traffic, `sudo ufw reject 9101/tcp` rejects it, and `sudo ufw delete deny 9101/tcp` removes it.

Result: (write what happened, add a screenshot of the portcheck output and the tcpdump flags)

---

## 10. Errors Faced Today
- Example: `curl: (28) Connection timed out` to a service that was running
- Cause: a firewall rule was **dropping** the packets, so the SYN got no reply
- Fix: found with `portcheck.sh` (FILTERED) and `tcpdump` (SYN repeated), then removed the rule

Full story: `troubleshooting/error-01.md`

---

## 11. Quick Q&A (for interviews)

**Q: A user can't connect to your server on port 443. How do you debug it?**
From the bottom up: DNS (`dig`), route and reachability (`ping`, `traceroute`), the port (`nc -vz host 443`, refused or timeout?), then firewall rules and Security Groups, then on the server `ss -tulpn` to see whether the app listens on `0.0.0.0:443`, and finally the app logs.

**Q: "Connection refused" vs "Connection timed out"?**
Refused: the host answered with a reset, so it is reachable but nothing listens (or a REJECT rule). Timed out: no answer at all, so packets are dropped by a firewall, Security Group or bad route, or the host is down.

**Q: Why does the app work on the server but not from my laptop?**
It may listen only on `127.0.0.1` (check with `ss -tlnp`), or a firewall/Security Group blocks the port.

**Q: How do you check which process uses a port?**
`sudo ss -tulpn | grep :PORT` or `sudo lsof -i :PORT`.

**Q: What does `* * *` in traceroute mean?**
That hop gave no reply, often because it filters ICMP/UDP. It is only a real problem if every hop after it also times out.

**Q: When would you use tcpdump?**
When the usual tools give mixed signals. It shows whether the SYN leaves my machine, whether a SYN-ACK or RST comes back, and so proves where the packets stop.

**Q: What does a repeated SYN with no SYN-ACK tell you?**
Packets are being dropped before they reach a listening service: firewall, Security Group/NACL, routing, or the server is down.

**Q: Ping fails but the website works. Why?**
ICMP is blocked (common with firewalls and Security Groups), which does not affect TCP traffic on port 80 or 443.

**Q: Many connections in CLOSE-WAIT. What does it mean?**
The remote side closed the connection but my application did not close its end, which suggests an application bug (a connection or resource leak).

**Q: Security Group vs NACL?**
A Security Group is stateful and attached to an instance (return traffic is allowed automatically). A NACL is stateless and attached to a subnet, so return traffic needs its own rule. Both drop silently.

**Q: How do you find where latency comes from?**
`mtr` or `traceroute` shows which hop adds the delay, and `curl -w` timing shows whether it is DNS, connect, TLS or the application.

---

## 12. Summary in 3 lines
1. Debug bottom up (IP and route, DNS, path, port, firewall, app) and stop at the first failing step.
2. Open = connects, **refused = reachable but nothing listening (RST)**, **timeout = packets dropped (SYN repeated, no SYN-ACK)**.
3. Tools: `ss -tulpn` (who listens and on which address), `nc -vz` / `portcheck.sh` (port state), `traceroute` / `mtr` (path), `tcpdump` (the packets themselves).