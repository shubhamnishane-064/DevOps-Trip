# Error Log: Firewalls, iptables/ufw & VPN — Troubleshooting Journal

## 1. Symptom (what I saw)

### Error 1: SSH Connection Timed Out
```text
ssh: connect to host 192.168.1.100 port 22: Connection timed out
```

### Error 2: UFW Blocking Incoming Connections
```text
Connection to server failed.
Incoming connections were blocked by the UFW firewall.
```

### Error 3: iptables Blocking Network Traffic
```text
Network traffic was blocked by iptables rules.
Unable to establish a connection to the target service.
```

## 2. Context (what I was doing)

I was troubleshooting network connectivity and firewall configuration on a Linux system.

The issues occurred while:
- Connecting to a remote server using SSH.
- Configuring UFW firewall rules to allow incoming connections.
- Inspecting iptables rules to identify blocked network traffic.

Environment:
- Operating System: Ubuntu/Linux
- Firewall: UFW and iptables
- Protocol: SSH (TCP port 22)
- Tools: ssh, ufw, iptables, ping, ss

## 3. Investigation (how I debugged)

- [ ] Read the error carefully.
- [ ] Checked firewall status and active rules.
- [ ] Checked whether the SSH service was running.
- [ ] Verified the target IP address and port.
- [ ] Inspected iptables rules for blocked traffic.
- [ ] Tested the connection after applying the fix.
- [ ] Searched documentation and troubleshooting forums.

Commands tried:

```bash
# Error 1: SSH connection timeout

# Test SSH connectivity
ssh -v user@192.168.1.100

# Check whether SSH is listening on port 22
sudo ss -tlnp | grep ':22'

# Check firewall status
sudo ufw status verbose


# Error 2: UFW blocking incoming connections

# Check UFW rules
sudo ufw status numbered

# Check whether SSH is allowed
sudo ufw status | grep '22'


# Error 3: iptables blocking network traffic

# List active firewall rules
sudo iptables -L -n -v

# Display firewall rules in command format
sudo iptables -S

# Check packet counters for blocked traffic
sudo iptables -L INPUT -n -v
```

## 4. Root Cause

**Error 1: SSH Connection Timed Out**

The SSH connection timed out because network traffic to the remote server was not reaching the SSH service. Possible causes include a firewall rule blocking TCP port 22, an incorrect IP address, a network routing problem, or an unavailable server.

**Error 2: UFW Blocking Incoming Connections**

UFW was configured to block incoming connections, and the required port was not allowed by the firewall rules.

**Error 3: iptables Blocking Network Traffic**

An iptables rule was preventing the required network traffic from reaching its destination. The rule could have been an explicit DROP or REJECT rule, or a default policy that blocked the traffic.

## 5. Fix

### Fix 1: SSH Connection Timed Out

```bash
# Allow SSH through UFW
sudo ufw allow 22/tcp

# Check firewall status
sudo ufw status verbose

# Test the SSH connection again
ssh user@192.168.1.100
```

### Fix 2: UFW Blocking Incoming Connections

```bash
# Allow incoming SSH connections
sudo ufw allow 22/tcp

# Reload UFW rules
sudo ufw reload

# Verify the firewall configuration
sudo ufw status numbered
```

### Fix 3: iptables Blocking Network Traffic

Inspect the firewall rules and identify the specific rule blocking the required traffic.

For example, to insert an SSH allow rule before other INPUT-chain rules:

```bash
# Allow new inbound SSH connections
sudo iptables -I INPUT -p tcp --dport 22 \
  -m conntrack --ctstate NEW -j ACCEPT

# Verify the rules
sudo iptables -L INPUT -n -v
```

**Note:** These commands are example fixes, not verified results from your system. Confirm the correct interface, port, source restrictions, and firewall policy before applying changes. If UFW manages your firewall, prefer managing rules through UFW to avoid inconsistent configurations.

## 6. Prevention / Lesson Learned

- Check firewall status before troubleshooting SSH connectivity.
- Allow the required SSH port before enabling restrictive firewall rules.
- Inspect iptables rules and packet counters to identify blocked traffic.
- Verify that the SSH service is running and listening on the expected port.
- Confirm the target IP address and network routing configuration.
- Apply only the firewall rules required for the intended traffic.
- Keep a backup of firewall configurations before making changes.
- Test connectivity after each change to identify which fix resolved the issue.
- Avoid flushing firewall rules or disabling the firewall on a remote server without a recovery