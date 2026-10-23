# Notes: Day 2 - DNS (Domain Name System)

**Week 2 | Tuesday** | Topic: how names become IP addresses, and how to debug it

---

## 1. What is DNS?
- Computers talk using **IP addresses**, but people remember **names**.
- **DNS** is the phone book of the internet: it turns `google.com` into an IP like `142.250.x.x`.
- Uses **port 53** (UDP for normal queries, TCP for big answers and zone transfers).

```
Me:   "What is the IP of myapp.example.com?"
DNS:  "203.0.113.10"
Me:   connects to 203.0.113.10
```

> If a website opens by IP but not by name, the problem is **DNS**, not the network.

---

## 2. The DNS Hierarchy (a name read from right to left)

```
www . myapp . example . com .
 |      |        |       |   |
 host  sub     domain   TLD  root (the final dot)
```

| Level | Example | Job |
|---|---|---|
| **Root** | `.` | Knows where each TLD server is |
| **TLD** | `.com`, `.org`, `.in` | Knows who runs each domain |
| **Authoritative** | `ns1.example.com` | Holds the real records of the domain (the final answer) |
| **Recursive resolver** | `8.8.8.8`, ISP, AWS | Does the searching for me and caches the answer |

---

## 3. How a Lookup Works (step by step)

1. App asks the OS: "IP of `myapp.example.com`?"
2. OS checks its **cache**, then **`/etc/hosts`** (order set in `/etc/nsswitch.conf`).
3. Not found, so it asks the **recursive resolver** from `/etc/resolv.conf`.
4. Resolver checks its own cache. If empty, it asks:
   - a **root server**, which says "ask the `.com` servers"
   - a **TLD server**, which says "ask `ns1.example.com`"
   - the **authoritative server**, which gives the real answer
5. Resolver returns the answer and **caches it for the TTL time**.

```
App -> OS cache -> /etc/hosts -> Resolver -> Root -> TLD -> Authoritative
                                    |
                                    +-- answer cached for TTL seconds
```

**TTL (Time To Live):** how many seconds an answer may be cached. Before moving a server to a new IP, lower the TTL (for example to 300) a day before, so the change spreads quickly.

---

## 4. Local Files

### `/etc/hosts` (my own mini DNS)
```
127.0.0.1     localhost
192.168.1.50  web1 web1.local
10.0.1.20     db1
```
- Format: `IP  name  [aliases]`.
- Checked **before** DNS, so it overrides it.
- Good for tests, for example pointing a name to a new server before changing real DNS.

### `/etc/resolv.conf` (which DNS server to ask)
```
nameserver 8.8.8.8
nameserver 1.1.1.1
search example.com
```
| Line | Meaning |
|---|---|
| `nameserver` | DNS server to ask (up to 3) |
| `search` | Suffix tried for short names (`web1` becomes `web1.example.com`) |

On Ubuntu this file often points to `127.0.0.53`, which is the local **systemd-resolved** service. Check the real servers with:
```bash
resolvectl status
```
Don't edit the file by hand on such systems, because it is generated. Change the DNS in netplan or NetworkManager instead.

### `/etc/nsswitch.conf` (lookup order)
```
hosts:  files dns
```
`files` = `/etc/hosts` first, then `dns`. This is why a hosts-file entry wins.

---

## 5. Record Types

| Type | Meaning | Example |
|---|---|---|
| **A** | Name -> IPv4 | `app.example.com  A  203.0.113.10` |
| **AAAA** | Name -> IPv6 | `app.example.com  AAAA  2001:db8::10` |
| **CNAME** | Alias to another name | `www  CNAME  app.example.com` |
| **MX** | Mail servers (with priority) | `example.com  MX  10 mail.example.com` |
| **TXT** | Free text (SPF, domain proof) | `"v=spf1 include:... -all"` |
| **NS** | Name servers of the domain | `example.com  NS  ns1.example.com` |
| **SOA** | Zone info (serial, refresh) | start of authority |
| **PTR** | IP -> name (reverse lookup) | `10.113.0.203.in-addr.arpa PTR app.example.com` |
| **SRV** | Service location (host + port) | used by some apps |

Remember
- A **CNAME** can't be used at the bare domain (`example.com`), only on names like `www`. (AWS Route 53 offers an **Alias** record for that case.)
- A name with a CNAME can't also have other records.
- Lower MX number = higher priority.

---

## 6. Commands

```bash
# dig (best tool, from package dnsutils / bind-utils)
dig example.com                    # full answer
dig +short example.com             # only the answer
dig example.com MX                 # one record type
dig @8.8.8.8 example.com           # ask a specific DNS server
dig +trace example.com             # follow root -> TLD -> authoritative
dig -x 203.0.113.10                # reverse lookup (IP -> name)
dig example.com ANY                # many servers now refuse ANY, so ask each type

# other tools
nslookup example.com               # older, simple
nslookup -type=MX example.com
host example.com                   # short output
getent hosts example.com           # what the OS really uses (includes /etc/hosts)

# systemd-resolved
resolvectl status                  # DNS servers in use
resolvectl query example.com
sudo resolvectl flush-caches       # clear the local DNS cache
```

### Reading `dig` output
```
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 4711
;; QUESTION SECTION:
;myapp.example.com.        IN  A

;; ANSWER SECTION:
myapp.example.com.  300    IN  A   203.0.113.10
                    ^TTL        ^type ^answer

;; Query time: 23 msec
;; SERVER: 8.8.8.8#53(8.8.8.8)
```
| Status | Meaning |
|---|---|
| **NOERROR** | Worked (if the ANSWER section is empty, the name exists but not that record type) |
| **NXDOMAIN** | The name does not exist |
| **SERVFAIL** | The DNS server could not get an answer (broken or misconfigured DNS) |
| **REFUSED** | The server refuses to answer me |

> **Important:** `dig` and `nslookup` ask the DNS server directly and **ignore `/etc/hosts`**. `ping`, `curl` and `ssh` use the OS, so they **do** see `/etc/hosts`. If `dig` and `ping` disagree, check the hosts file.

---

## 7. Troubleshooting Flow (from Day 1 to DNS)

```bash
ping -c 2 8.8.8.8            # works? network is fine
ping -c 2 google.com         # fails? then DNS is the problem
cat /etc/resolv.conf         # is a nameserver set?
resolvectl status            # what is systemd-resolved using?
dig @8.8.8.8 google.com      # does a public DNS answer?
dig google.com               # does MY DNS server answer?
getent hosts google.com      # what does the OS see?
grep google /etc/hosts       # a wrong override?
```

| Message | Usual cause |
|---|---|
| `Temporary failure in name resolution` | **No usable DNS server** (empty `resolv.conf`, DNS unreachable) |
| `Name or service not known` | The DNS server answered "no such name" (typo, missing record), or the search domain is wrong |
| Works by IP, fails by name | DNS problem |
| Old IP after a change | Cache / TTL (`resolvectl flush-caches`, wait for TTL) |
| `curl` works with `-H "Host: ..."` but not by name | Missing DNS record |

---

## 8. DNS in AWS (looking ahead)
- **Route 53** = AWS DNS service (hosted zones, records, health checks, **Alias** records).
- Inside a VPC, DNS is provided at the **VPC base address + 2** (for `10.0.0.0/16` that is `10.0.0.2`) and at `169.254.169.253`.
- EC2 gets names like `ec2-3-110-x-x.ap-south-1.compute.amazonaws.com`.
- **Private hosted zones** give internal names (`db.internal`) that resolve only inside the VPC.
- VPC settings **enableDnsSupport** and **enableDnsHostnames** must be on for this to work.

---

## 9. Lab (Hands-on)

**Goal:** query DNS, override a name with `/etc/hosts`, and break and fix DNS.

```bash
# 1. install tools
sudo apt install dnsutils -y

# 2. look up records
dig +short google.com
dig google.com MX
dig +short NS github.com
dig +trace github.com | head -30
dig -x 8.8.8.8 +short

# 3. compare DNS servers
dig @8.8.8.8 github.com | grep "Query time"
dig @1.1.1.1 github.com | grep "Query time"

# 4. see my DNS settings
cat /etc/resolv.conf
resolvectl status | head -20

# 5. override with /etc/hosts
echo "203.0.113.99  test.local" | sudo tee -a /etc/hosts
getent hosts test.local        # shows 203.0.113.99
dig +short test.local          # shows nothing (dig ignores the hosts file)
# clean up
sudo sed -i '/test.local/d' /etc/hosts

# 6. my script
./dnscheck.sh github.com
./dnscheck.sh github.com 8.8.8.8
./dnscheck.sh thisdoesnotexist12345.com
```

**Break and fix (for the error log)**
```bash
sudo cp /etc/resolv.conf /etc/resolv.conf.bak
# if resolv.conf is a normal file, empty it; on systemd-resolved systems, use a test VM
ping -c 2 google.com           # Temporary failure in name resolution
ping -c 2 8.8.8.8              # still works
# restore
sudo cp /etc/resolv.conf.bak /etc/resolv.conf
```

Result: (write what happened, add a screenshot)

---

## 10. Errors Faced Today
- Example: `ping: google.com: Temporary failure in name resolution` while `ping 8.8.8.8` works
- Cause: no working `nameserver` in `/etc/resolv.conf`
- Fix: restore the nameserver (or the systemd-resolved link), then test with `dig`

Full story: `troubleshooting/error-01.md`

---

## 11. Quick Q&A (for interviews)

**Q: What is DNS?**
A system that translates domain names into IP addresses, using a hierarchy of root, TLD and authoritative servers, with caching.

**Q: What happens when you type a URL in the browser (the DNS part)?**
Browser and OS caches, then `/etc/hosts`, then the recursive resolver. The resolver asks root, then TLD, then the authoritative server, and caches the answer for its TTL. Then the browser connects to the IP.

**Q: A vs CNAME?**
A maps a name to an IPv4 address. CNAME makes a name an alias of another name. A CNAME can't be used on the bare domain.

**Q: What is TTL?**
How long (in seconds) a DNS answer may be cached. Lower it before a migration so the change spreads fast.

**Q: What is an MX record?**
It says which mail servers accept email for the domain, with a priority (lower is preferred).

**Q: `dig` vs `nslookup`?**
Both query DNS. `dig` gives more detail (TTL, status, sections, `+trace`) and is preferred for troubleshooting. Neither reads `/etc/hosts`.

**Q: Website opens by IP but not by name. What do you check?**
It's DNS. Check `/etc/resolv.conf` or `resolvectl status`, then `dig @8.8.8.8 name` to test a public server, then `dig name` against my server, and finally the hosts file.

**Q: NXDOMAIN vs SERVFAIL?**
NXDOMAIN means the name does not exist. SERVFAIL means the DNS server failed to get an answer (a broken or misconfigured server).

**Q: What is `/etc/hosts` for?**
A local name-to-IP list checked before DNS. Used for tests and overrides.

**Q: How does DNS work inside an AWS VPC?**
The VPC has a built-in resolver at the base IP + 2 (and 169.254.169.253). Route 53 hosts public and private zones, and Alias records can point the bare domain to AWS resources.

---

## 12. Summary in 3 lines
1. DNS turns names into IPs: cache, then `/etc/hosts`, then the resolver, which asks root, TLD and authoritative servers; answers are cached for the TTL.
2. Know the records: A, AAAA, CNAME, MX, TXT, NS, PTR, and the dig statuses NOERROR, NXDOMAIN, SERVFAIL.
3. Debug: `ping IP` works but `ping name` fails -> check `resolv.conf`, `resolvectl status`, then `dig @8.8.8.8 name`.