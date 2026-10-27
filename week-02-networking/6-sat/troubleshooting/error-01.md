# Error Log: Service is running but the connection times out



## 1. Symptom (what I saw)
```
$ curl --connect-timeout 3 http://127.0.0.1:9101/
curl: (28) Connection timed out after 3001 milliseconds
```
Earlier the same URL worked, and the web server process was still running.

## 2. Context (what I was doing)
I was practising firewall rules with `iptables` on a test machine. I added a rule for port 9101 to see its effect. Afterwards the service looked healthy but nothing could connect.

## 3. Investigation (how I debugged)
I used the bottom-up method:

- [x] Is the service running and listening?
- [x] Is the port open, closed or filtered?
- [x] Do packets leave and do answers come back? (`tcpdump`)
- [x] Is a firewall rule involved?

Commands tried:
```bash
sudo ss -tlnp | grep 9101
# LISTEN 0 5 0.0.0.0:9101 users:(("python3",pid=247,fd=3))   -> the app IS listening on all interfaces

./portcheck.sh 127.0.0.1 9101
# 9101   FILTERED  (no answer for 3s: firewall or Security Group dropping packets?)

sudo tcpdump -l -i lo -nn 'tcp port 9101'
# +0.0s ... Flags [S]
# +1.0s ... Flags [S]      <- the same SYN again and again
# +2.0s ... Flags [S]      <- and never a [S.] (SYN-ACK)

sudo iptables -S INPUT
# -P INPUT ACCEPT
# -A INPUT -p tcp -m tcp --dport 9101 -j DROP                  -> found it
```

## 4. Root Cause
A firewall rule (`-A INPUT -p tcp --dport 9101 -j DROP`) was **silently dropping** the incoming SYN packets before they reached the application. The client got no answer, so it retried the SYN and finally timed out. The application itself was fine.

Key clues that pointed to a firewall and not to the app:
- `ss` showed the app **listening** on `0.0.0.0:9101`.
- The result was a **timeout** (28), not "connection refused" (7).
- `tcpdump` showed **SYN retransmissions with no SYN-ACK**.

## 5. Fix
```bash
sudo iptables -D INPUT -p tcp --dport 9101 -j DROP     # remove the rule
sudo iptables -S INPUT                                  # confirm it is gone
./portcheck.sh 127.0.0.1 9101                           # 9101  OPEN
curl -I http://127.0.0.1:9101/                          # HTTP/1.0 200 OK
```
With `ufw`: `sudo ufw status numbered`, then `sudo ufw delete <number>`.
In AWS, the same symptom means: add an inbound **Security Group** rule for the port from my IP (and check the NACL and route table).

## 6. Prevention / Lesson Learned
- **Timeout = packets dropped. Refused = reachable but nothing listening.** The wording of the error points to the cause.
- Check `ss -tulpn` first. If the app listens on `0.0.0.0` and the connection still times out, suspect the firewall, Security Group or route.
- Use `tcpdump` to prove where packets stop (SYN without SYN-ACK).
- When testing firewall rules, use a non-SSH port, keep a second session open, and write down every rule I add so I can remove it.
- Plain `iptables` rules are not saved across reboots, so a reboot clears them, but `ufw` rules and saved rule sets stay.
- Record firewall changes in the repo (a note or a script) so the next person knows what is open and why.

