# Networking for DevOps | Week 2 - Monday: TCP/IP, IP addresses, subnets and CIDR

**Date:** 05-10-2026  |  **Time spent:** 2-3 hrs  |  **Status:** [x] Done

## Today's Goal
Understand how computers find and talk to each other: IP addresses, subnets, CIDR, gateways, ports, and TCP vs UDP. Learn to inspect and test a network from the command line.

## Plan (checklist)
- [x] Learn the concept (TCP/IP model, IPv4, private ranges, CIDR)
- [x] Hands-on lab: inspect my network and calculate subnets
- [x] Write `cidr.sh`, a small subnet calculator
- [x] Write notes in `documentation/`
- [x] Log one error in `troubleshooting/`
- [x] Commit and push with a clear message

## What I Did
- Learned the 4-layer TCP/IP model and where HTTP, TCP and IP fit (Layer 7, 4, 3).
- Learned IPv4, public vs private ranges (10.x, 172.16-31.x, 192.168.x), localhost and `0.0.0.0`.
- Learned subnet masks and CIDR: `/24` = 256 addresses (254 usable), `/26` = 64 (62 usable).
- Learned gateway, router, NAT, DHCP, MAC address, ports, TCP vs UDP and the three-way handshake.
- Practised `ip a`, `ip route`, `ping`, `ss -tulpn`, `curl -I`, `traceroute`.
- Wrote `cidr.sh`, which calculates network, broadcast, first and last host and usable hosts for any `IP/prefix`.
- Connected it to AWS: a VPC of `10.0.0.0/16` split into `/24` subnets, with 5 reserved addresses per subnet.

## Scripts in this folder
| File | What it does |
|---|---|
| [`cidr.sh`](cidr.sh) | `./cidr.sh 192.168.1.130/26` prints mask, network, broadcast, first and last host, usable hosts |

## Lab Summary
```bash
ip -br a
ip route
ping -c 3 <gateway>
ping -c 3 8.8.8.8
ping -c 3 google.com
sudo ss -tulpn
./cidr.sh 192.168.1.130/26
```
Result: found my IP, mask and gateway, tested each step from the machine out to the internet, and checked subnet answers with `cidr.sh`. (Add a screenshot in `documentation/images/`. Hide public IPs.)

## What I Learned
- Usable hosts = 2^(32 - prefix) - 2.
- Two machines talk directly only if they are in the same subnet; otherwise they use the gateway.
- Debug network problems from the inside out: IP, route, gateway, internet by IP, internet by name.
- `Network is unreachable` means no route; check for a default gateway.

## Errors Faced
- `ping: connect: Network is unreachable` (missing default gateway): see [`troubleshooting/error-01.md`](troubleshooting/error-01.md)

## Notes
Full notes: [`documentation/notes.md`](documentation/notes.md)

## Tomorrow
Day 2: DNS deep dive (`dig`, `nslookup`, `/etc/hosts`, `/etc/resolv.conf`, record types A, CNAME, MX, TXT).