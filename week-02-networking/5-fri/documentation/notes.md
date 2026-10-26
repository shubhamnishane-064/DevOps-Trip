# Notes: Firewalls, iptables/ufw, VPN basics

## Key Concepts

### What is a firewall?
- A **firewall** filters network traffic based on rules (allow/deny).
- It sits between a **trusted** network (your machine/LAN) and an **untrusted** one (the internet).
- Can be **host-based** (on the machine, e.g. iptables/ufw) or **network-based** (on a router/cloud security group).

### Types of firewalls
| Type | Description |
|---|---|
| **Packet filter (stateless)** | Looks at each packet independently — src/dst IP, port, protocol. Fast, dumb. |
| **Stateful** | Remembers connections (`NEW`, `ESTABLISHED`, `RELATED`) — smarter, most modern firewalls. |
| **Application-layer (L7 proxy)** | Inspects payload (HTTP, DNS). e.g. WAF. |
| **Cloud security group** | Managed virtual firewall (AWS SG, GCP VPC rules). |

### Netfilter / iptables / nftables
- **Netfilter** = the kernel framework that does the actual packet filtering.
- **iptables** = the classic user-space tool that configures Netfilter rules.
- **nftables** = the modern replacement for iptables (single tool, better syntax, faster).
- **ufw** = "Uncomplicated Firewall" — a friendly wrapper around iptables for Ubuntu/Debian.
- **firewalld** = the friendly wrapper on RHEL/CentOS/Fedora.

### iptables chains (order matters)
- **PREROUTING** → routing decision → **INPUT** (to local) / **FORWARD** (through) / **OUTPUT** (from local)
- **POSTROUTING** on the way out.
- Built-in targets: `ACCEPT`, `DROP`, `REJECT`, `LOG`, `RETURN`.

### iptables common tables
| Table | Purpose |
|---|---|
| `filter` | Default — allow/deny packets (`INPUT`, `FORWARD`, `OUTPUT`). |
| `nat` | Address translation (`PREROUTING`, `POSTROUTING`, `OUTPUT`). |
| `mangle` | Packet header modification (rarely touched). |

### VPN basics
- **VPN (Virtual Private Network)** = encrypted tunnel between client and server over an untrusted network.
- Provides: **confidentiality** (encryption), **integrity** (tamper detection), **authentication** (who you are).
- **Site-to-site VPN** = connects two networks (office ↔ cloud).
- **Remote-access VPN** = connects one user to a network (laptop → office).
- Common protocols:

  | Protocol | Notes |
  |---|---|
  | **WireGuard** | Modern, fast, tiny codebase, UDP. Recommended. |
  | **OpenVPN** | Mature, TLS-based, TCP or UDP. Very compatible. |
  | **IPsec** | Standard for site-to-site; built into kernels. |
  | **L2TP/IPsec** | Common for mobile clients. |
  | **PPTP** | **Obsolete and insecure — do not use.** |

- **Split tunnel** = only some traffic goes through VPN; **full tunnel** = all traffic does.

### Key distinction
- Firewall = **who can talk to whom**.
- VPN = **encrypted, authenticated path** between two points.
- They're complementary: a VPN often has its own firewall rules (e.g. allow `51820/udp` for WireGuard).

---

## Important Commands

### ufw (Ubuntu/Debian — the easy one)
```bash
sudo ufw status verbose            # show rules + default policy
sudo ufw enable                    # turn on (prompts to keep SSH open)
sudo ufw disable                   # turn off

sudo ufw default deny incoming     # default deny inbound
sudo ufw default allow outgoing    # default allow outbound

sudo ufw allow ssh                 # allow port 22
sudo ufw allow 80/tcp              # allow HTTP
sudo ufw allow 443/tcp             # allow HTTPS
sudo ufw allow from 10.0.0.0/8 to any port 22   # SSH only from LAN
sudo ufw deny 23                   # block telnet
sudo ufw delete allow 80/tcp       # remove a rule
sudo ufw reset                     # wipe all rules
sudo ufw app list                  # known app profiles (Nginx, OpenSSH…)
```
### What's the difference between a firewall and a VPN?"
Answer:

    "They do different jobs and complement each other.

        A firewall controls who can talk to whom — it filters traffic based on IP, port, and protocol. It's about access control.

        A VPN creates an encrypted, authenticated tunnel between two points over an untrusted network. It's about confidentiality and integrity.

    Example: my server has a firewall allowing only port 51820/UDP. That's the firewall. WireGuard runs on that port and encrypts all traffic between my laptop and the server. That's the VPN. The firewall says 'you may enter'; the VPN says 'and here's the encrypted channel you enter through.'

    So: firewall = gatekeeper; VPN = secure tunnel. They're used together."

### What's the difference between a ufw and iptable?"
Answer:
      ufw and iptables both configure the same kernel firewall. ufw is a friendly frontend — simple syntax like ufw allow 22/tcp. iptables is the low-level tool — more verbose, like iptables -A INPUT -p tcp --dport 22 -j ACCEPT. ufw is easier to use, but iptables gives finer control for NAT and complex rules."

      . Memorize the phrase "friendly frontend around iptables"
