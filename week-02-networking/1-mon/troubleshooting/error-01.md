# Error Log: ping says "Network is unreachable"

**Date:** 05-10-2026 |  **Day:** Week 2 Monday  |  **Severity:** Medium

## 1. Symptom (what I saw)
```
$ ping -c 3 8.8.8.8
ping: connect: Network is unreachable
```
The machine could not reach anything outside its own network.

## 2. Context (what I was doing)
I set a static IP on a test VM to practise subnets. Before the change, internet access worked. After the change, ping to the internet failed.

## 3. Investigation (how I debugged)
I tested from the inside out, one layer at a time:

- [x] Do I have an IP address?
- [x] Do I have a default gateway?
- [x] Can I reach the gateway?
- [x] Can I reach the internet by IP?
- [x] Can I reach it by name?

Commands tried:
```bash
ip -br a
# eth0   UP   192.168.1.50/24                 -> IP is fine

ip route
# 192.168.1.0/24 dev eth0 proto kernel scope link src 192.168.1.50
# (there is NO line starting with "default via")   -> missing gateway

ping -c 2 192.168.1.1
# 64 bytes from 192.168.1.1: time=1.2 ms       -> router is reachable on the local network

ping -c 2 8.8.8.8
# ping: connect: Network is unreachable        -> no route to the outside
```

## 4. Root Cause
When I set the static IP, I only set the address and mask. I did not set the **default gateway**. With no default route, the machine only knew how to reach its own subnet (`192.168.1.0/24`), so anything outside it was "unreachable".

## 5. Fix
Temporary fix (lost after reboot):
```bash
sudo ip route add default via 192.168.1.1
ip route
# default via 192.168.1.1 dev eth0

ping -c 3 8.8.8.8        # works
ping -c 3 google.com     # works (DNS was already set)
```

```bash
sudo netplan try        # safe test, rolls back if I lose the connection
sudo netplan apply
```

## 6. Prevention / Lesson Learned
- A static IP needs **4 things**: address, mask (CIDR), gateway, DNS.
- Debug from the bottom up: IP -> route -> gateway -> internet by IP -> by name.
- `Network is unreachable` points to a **routing** problem (no route). `Destination Host Unreachable` points to a host or local-network problem. 100% packet loss with no message often means a **firewall**.
- Use `netplan try` instead of `apply`, so a mistake can't lock me out.

