# Networking for DevOps | Week 2 - Friday: Firewalls, iptables/ufw, VPN Basics

## Today's Goal
Learn the fundamentals of firewalls, Linux firewall management using iptables and UFW, and VPN basics.

## Plan (checklist)
- [ ] Learn the concepts (30–45 min)
- [ ] Complete the hands-on lab (60–90 min)
- [ ] Write notes in `documentation/`
- [ ] Log one error in `troubleshooting/`
- [ ] Commit and push with a clear message

## What I Did
- Studied the basics of firewalls and how they filter incoming and outgoing network traffic.
- Explored UFW commands for managing firewall rules in Linux.
- Learned how iptables chains and rules control network traffic.
- Reviewed VPN fundamentals, including encrypted connections and secure remote access.
- Practiced checking firewall status and inspecting network connections.

### Commands Practiced
```bash
# Check UFW status
sudo ufw status verbose

# Display numbered UFW rules
sudo ufw status numbered

# Allow SSH connections
sudo ufw allow 22/tcp

# List iptables rules
sudo iptables -L -n -v

# Display iptables rules in command format
sudo iptables -S

# Check listening ports
sudo ss -tulpn

# Display network interfaces and IP addresses
ip addr show

# Display the routing table
ip route show
```



## What I Learned
- A firewall controls network traffic according to configured security rules.
- UFW provides a simpler interface for managing Linux firewall rules.
- iptables uses tables, chains, and rules to filter and manage packets.
- Incoming SSH connections typically use TCP port 22.
- Incorrect firewall rules can block SSH access and other network services.
- VPNs create protected connections over networks that may not be trusted.
- VPN troubleshooting requires checking firewall rules, network interfaces, routing, and connectivity.
- Firewall changes should be tested carefully to avoid losing remote access.

## Errors Faced

### 1. SSH Connection Timed Out
- **Possible cause:** The SSH service is unreachable because of firewall rules, routing issues, or an incorrect IP address.
- **Troubleshooting:** Checked SSH connectivity, listening ports, and firewall status.
- **Possible fix:** Allow the required SSH traffic and verify network connectivity.

### 2. UFW Blocking Incoming Connections
- **Possible cause:** The firewall does not have an allow rule for the required port.
- **Troubleshooting:** Inspected UFW status and numbered rules.
- **Possible fix:** Add an appropriate allow rule for the required service.

### 3. iptables Blocking Network Traffic
- **Possible cause:** An iptables rule or default chain policy blocks the required traffic.
- **Troubleshooting:** Inspected iptables rules and packet counters.
- **Possible fix:** Identify the blocking rule and update the firewall policy appropriately.

For detailed troubleshooting steps, commands, root causes, and fixes, see [`troubleshooting/error-01.md`](troubleshooting/error-01.md).


## Tomorrow
- Continue with the next topic in the Networking for DevOps learning plan.
- Review today's firewall and VPN concepts.
- Finish any incomplete hands-on exercises.
- Update documentation with actual command outputs and observations.
- Commit and push the completed work to the Git repository.