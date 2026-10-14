# Notes: Day 1 - TCP/IP, IP Addresses, Subnets and CIDR

**Week 2 | Monday** | Topic: how computers find and talk to each other

---

## 1. What is a Network?
- A **network** = computers connected so they can share data.
- **Protocol** = a set of rules for talking (like a language). Examples: HTTP, DNS, TCP, IP.
- Every device needs an **IP address**, like a house address for letters.

---

## 2. TCP/IP Model (4 layers)

| Layer | Job | Examples |
|---|---|---|
| **Application** | What the user program uses | HTTP, HTTPS, DNS, SSH, FTP |
| **Transport** | Delivers data to the right program (port) | TCP, UDP |
| **Internet** | Finds the path between machines (IP address) | IP, ICMP (ping) |
| **Network access** | Sends bits on the cable / Wi-Fi | Ethernet, Wi-Fi, MAC address |

Flow: my request -> split into **packets** -> each packet gets an IP address and port -> travels through routers -> rebuilt at the other side.

> The OSI model has 7 layers (Physical, Data Link, Network, Transport, Session, Presentation, Application). For interviews, remember: **Network = Layer 3 (IP)**, **Transport = Layer 4 (TCP/UDP)**, **Application = Layer 7 (HTTP)**. "Layer 7 load balancer" means it understands HTTP.

---

## 3. IP Address (IPv4)
- 32 bits, written as 4 numbers (0-255): `192.168.1.10`.
- Each number is an **octet** (8 bits). Example: `192` = `11000000`.
- About 4.3 billion addresses. IPv6 (like `2001:db8::1`) exists because IPv4 is running out.

### Public vs Private IP
| Type | Used for | Reachable from internet? |
|---|---|---|
| **Public** | Servers on the internet | Yes |
| **Private** | Inside home / office / cloud networks | No (needs NAT) |

**Private ranges (memorise these)**
| Range | CIDR | Typical use |
|---|---|---|
| `10.0.0.0` - `10.255.255.255` | `10.0.0.0/8` | Big networks, AWS VPC |
| `172.16.0.0` - `172.31.255.255` | `172.16.0.0/12` | Medium networks, Docker |
| `192.168.0.0` - `192.168.255.255` | `192.168.0.0/16` | Home / small office |

Special addresses
- `127.0.0.1` = **localhost** (this machine itself).
- `0.0.0.0` = "all addresses" or "any" (a server listening on `0.0.0.0` accepts connections from anywhere).
- `169.254.x.x` = link-local (no DHCP answer was received).

---

## 4. Subnet Mask and CIDR

A **subnet** = a smaller network inside a bigger one. The **subnet mask** says which part of the IP is the **network** and which part is the **host**.

```
IP:    192.168.1.10
Mask:  255.255.255.0     (same as /24)

192.168.1 . 10
 network    host
```

**CIDR** writes the mask as a number: `/24` = the first 24 bits are the network part.

| CIDR | Subnet mask | Total IPs | Usable hosts |
|---|---|---|---|
| `/8` | 255.0.0.0 | 16,777,216 | 16,777,214 |
| `/16` | 255.255.0.0 | 65,536 | 65,534 |
| `/24` | 255.255.255.0 | 256 | 254 |
| `/25` | 255.255.255.128 | 128 | 126 |
| `/26` | 255.255.255.192 | 64 | 62 |
| `/27` | 255.255.255.224 | 32 | 30 |
| `/28` | 255.255.255.240 | 16 | 14 |
| `/30` | 255.255.255.252 | 4 | 2 |

**Formula:** total IPs = `2^(32 - prefix)`. Usable = total - 2.
The 2 lost: the **network address** (first) and the **broadcast address** (last).

### Worked example: `192.168.1.130/26`
- Block size = 64 (because 2^(32-26) = 64).
- Blocks: `.0-.63`, `.64-.127`, `.128-.191`, `.192-.255`. The IP `.130` is in the third block.
- Network: `192.168.1.128`
- Broadcast: `192.168.1.191`
- Usable hosts: `.129` to `.190` (62 hosts)

Check with my script:
```bash
./cidr.sh 192.168.1.130/26
```

**Same subnet?** Two IPs can talk directly only if they are in the **same subnet**. Otherwise traffic goes through the **gateway**.
- `192.168.1.10/24` and `192.168.1.20/24` -> same subnet.
- `192.168.1.10/24` and `192.168.2.20/24` -> different subnets, need a router.

---

## 5. Gateway, Router, NAT, DHCP

| Term | Simple meaning |
|---|---|
| **Gateway** (default gateway) | The router address my machine uses to reach other networks and the internet |
| **Router** | Connects networks and forwards packets |
| **NAT** | Lets many private IPs share one public IP |
| **DHCP** | Gives IP address, mask, gateway and DNS automatically |
| **DNS** | Turns names (google.com) into IPs (Day 2) |
| **MAC address** | Hardware address of a network card (e.g. `0a:1b:2c:3d:4e:5f`), works inside one local network |

Routing rule on a host: "If the destination is in my subnet, send it directly. If not, send it to the default gateway."

---

## 6. Ports, TCP and UDP

A **port** (0-65535) tells which program on a machine should get the data. IP = building, port = apartment number.

| Port | Service |
|---|---|
| 22 | SSH |
| 80 | HTTP |
| 443 | HTTPS |
| 53 | DNS |
| 25 | SMTP (email) |
| 3306 | MySQL |
| 5432 | PostgreSQL |
| 6379 | Redis |
| 3000 / 8080 | Dev apps |

| TCP | UDP |
|---|---|
| Reliable: checks that data arrived, in order | Fast, no checking |
| Needs a connection first | No connection |
| Web, SSH, email, databases | DNS, video calls, streaming, games |

### TCP three-way handshake
```
Client  --- SYN ------------->  Server     "Can we talk?"
Client  <-- SYN-ACK ----------  Server     "Yes, can you hear me?"
Client  --- ACK ------------->  Server     "Yes. Connection open."
```

---

## 7. Commands

```bash
ip a                     # my IP addresses and interfaces (short for: ip address)
ip -br a                 # brief version
hostname -I              # just my IPs
ip route                 # routing table (look for "default via ...")
ip r get 8.8.8.8         # which route will be used for this IP
ping -c 4 8.8.8.8        # is the target reachable? (-c 4 = 4 packets)
ping -c 4 192.168.1.1    # test my gateway
ss -tulpn                # listening ports and programs (t=tcp u=udp l=listening p=process n=numbers)
sudo ss -tulpn | grep :22
curl -I https://example.com    # check a web server answers
traceroute 8.8.8.8       # path through routers (install: sudo apt install traceroute)
cat /etc/resolv.conf     # DNS servers (Day 2)
```

Old commands you may see: `ifconfig` (use `ip a`), `netstat` (use `ss`), `route` (use `ip route`).

Reading `ip -br a`:
```
lo      UNKNOWN  127.0.0.1/8
eth0    UP       192.168.1.10/24
```
- `lo` = loopback (this machine). `eth0` / `ens5` / `enp0s3` = network card.
- `192.168.1.10/24` = IP and CIDR together.

Reading `ip route`:
```
default via 192.168.1.1 dev eth0
192.168.1.0/24 dev eth0 proto kernel scope link src 192.168.1.10
```
- First line: the **default gateway** is `192.168.1.1`.
- Second line: the local subnet is reached directly on `eth0`.

### Ping results
| Result | Meaning |
|---|---|
| `64 bytes from ... time=12 ms` | Reachable |
| `Destination Host Unreachable` | No path or the host is down |
| `Network is unreachable` | I have no route, often no default gateway |
| `Request timeout` / 100% loss | Blocked by firewall, or host is off |

---

## 8. Why this matters in AWS (looking ahead to Week 6)
- A **VPC** is my private network, with a CIDR range, e.g. `10.0.0.0/16`.
- **Subnets** split it: `10.0.1.0/24` (public), `10.0.2.0/24` (private).
- AWS **reserves 5 IPs** in each subnet (first 4 and the last), so a `/24` has **251** usable addresses.
- **Internet Gateway** = the door to the internet. **NAT Gateway** = lets private servers go out only.
- Subnets in the same VPC must **not overlap**.

---

## 9. Lab (Hands-on)

**Goal:** inspect my own network and calculate subnets.

```bash
# 1. my network details
ip -br a
ip route
hostname -I

# 2. test connectivity step by step
ping -c 3 127.0.0.1           # my own machine
ping -c 3 <my-gateway-ip>     # my router (from "default via")
ping -c 3 8.8.8.8             # internet by IP
ping -c 3 google.com          # internet by name (needs DNS)

# 3. listening ports
sudo ss -tulpn

# 4. subnet practice
./cidr.sh 192.168.1.130/26
./cidr.sh 10.0.0.0/16
./cidr.sh 172.16.5.9/20
```

**Questions to answer in my own words**
1. What is my IP, mask and gateway?
2. Is my IP private or public?
3. For `10.0.1.0/24`, how many usable hosts are there?
4. Are `192.168.1.200/26` and `192.168.1.10/26` in the same subnet?

(Answers: 4. No. `.200` is in `.192-.255`, `.10` is in `.0-.63`.)

Result: (write what happened, add a screenshot. Hide any public IP.)

---

## 10. Errors Faced Today
- Example: `ping: connect: Network is unreachable`
- Cause: no default gateway in the routing table
- Fix: add the route with `sudo ip route add default via <gateway-ip>`

Full story: `troubleshooting/error-01.md`

---

## 11. Quick Q&A (for interviews)

**Q: What is the difference between TCP and UDP?**
TCP is reliable and connection-based (web, SSH, databases). UDP is faster with no checking (DNS, streaming, video calls).

**Q: Explain the three-way handshake.**
SYN, SYN-ACK, ACK. The client asks, the server agrees, the client confirms, and then data flows.

**Q: What is a subnet mask / CIDR?**
It shows which part of the IP is the network and which is the host. `/24` means 24 network bits, 256 addresses, 254 usable.

**Q: How many usable hosts are in a /26?**
2^(32-26) = 64 total, minus 2 = 62.

**Q: Public vs private IP?**
Private IPs (10.x, 172.16-31.x, 192.168.x) work only inside a network. Public IPs are reachable on the internet. NAT connects the two.

**Q: What is a default gateway?**
The router a machine sends traffic to when the destination is outside its own subnet.

**Q: What is `0.0.0.0` vs `127.0.0.1`?**
`127.0.0.1` is localhost, this machine only. `0.0.0.0` means all interfaces (a server bound to it accepts connections from anywhere).

**Q: What is NAT?**
It lets many private IPs share one public IP by rewriting addresses on the way out and back.

**Q: Which port does SSH / HTTP / HTTPS / DNS use?**
22 / 80 / 443 / 53.

**Q: A server can't reach the internet. What do you check?**
`ip a` (do I have an IP?), `ip route` (is there a default gateway?), `ping <gateway>`, `ping 8.8.8.8` (internet by IP), `ping google.com` (DNS). The step that fails shows the problem layer.

---

## 12. Summary in 3 lines
1. IP addresses find the machine, ports find the program; TCP is reliable, UDP is fast.
2. CIDR (`/24`, `/26`) splits networks; usable hosts = 2^(32-prefix) - 2; private ranges are 10.x, 172.16-31.x, 192.168.x.
3. Debug in order: `ip a` -> `ip route` -> `ping gateway` -> `ping 8.8.8.8` -> `ping name`.