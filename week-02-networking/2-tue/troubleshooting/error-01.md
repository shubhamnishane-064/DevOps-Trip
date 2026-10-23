# Error Log: "Temporary failure in name resolution"

## 1. Symptom (what I saw)
```
$ ping -c 2 google.com
ping: google.com: Temporary failure in name resolution

$ ping -c 2 8.8.8.8
64 bytes from 8.8.8.8: icmp_seq=1 ttl=117 time=12.4 ms     <- works
```
The internet worked by IP but not by name.

## 2. Context (what I was doing)
I was practising DNS and edited `/etc/resolv.conf` to test different `nameserver` lines. After my change, every name lookup stopped working, including `apt update` and `curl`.

## 3. Investigation (how I debugged)
Following my Day 1 method, from the bottom up:

- [x] IP address and route fine? (`ip -br a`, `ip route`)
- [x] Internet by IP works? (`ping 8.8.8.8`)
- [x] Internet by name fails, so it must be DNS
- [x] Is a DNS server configured?
- [x] Does a public DNS server answer?

Commands tried:
```bash
ip route | head -1
# default via 192.168.1.1 dev eth0                -> routing is fine

ping -c 2 8.8.8.8
# works                                           -> network is fine

cat /etc/resolv.conf
# (empty, only comments)                          -> no nameserver at all

dig @8.8.8.8 google.com +short
# 142.250.x.x                                     -> public DNS works, so the problem is MY configuration

resolvectl status | head
# Global: DNS Servers: (none)                     -> nothing configured
```

## 4. Root Cause
`/etc/resolv.conf` had no `nameserver` line. The system had no DNS server to ask, so every name lookup failed with "Temporary failure". The network and the internet were fine, and the public DNS server answered when I asked it directly.

## 5. Fix
Quick test fix (temporary):
```bash
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
ping -c 2 google.com            # works
```
Proper fix on a systemd-resolved system (Ubuntu): restore the generated file and set DNS in the network config.
```bash
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
sudo systemctl restart systemd-resolved
resolvectl status | grep -A2 "DNS Servers"
```
Set DNS permanently in netplan:
```yaml
nameservers:
  addresses: [8.8.8.8, 1.1.1.1]
```
```bash
sudo netplan try && sudo netplan apply
```

## 6. Prevention / Lesson Learned
- Always back up before editing: `sudo cp /etc/resolv.conf /etc/resolv.conf.bak`.
- On systemd-resolved systems `/etc/resolv.conf` is generated, so don't hand-edit it. Change DNS in netplan or NetworkManager.
- Know the two messages: **"Temporary failure in name resolution"** means no usable DNS server, **"Name or service not known"** means the server answered that the name doesn't exist.
- "Works by IP, fails by name" always means DNS. Test with `dig @8.8.8.8 name` to see whether the problem is my resolver or the name.
- `dig` ignores `/etc/hosts`, while `ping` and `curl` use it, so a mismatch points to the hosts file.

- Day 2 notes: `../documentation/notes.md`, sections 4, 6 and 7