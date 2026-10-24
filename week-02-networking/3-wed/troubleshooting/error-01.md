# Error Log: curl: (7) Failed to connect ... Connection refused

## 1. Symptom (what I saw)
```
$ curl http://localhost:8081/
curl: (7) Failed to connect to localhost port 8081 after 0 ms: Couldn't connect to server
```

## 2. Context (what I was doing)
I started a small test web server with `python3 -m http.server 8081` for the lab. It worked at first. Later I ran `curl` again and the connection was refused.

## 3. Investigation (how I debugged)
Following the flow from Day 1 and 2:

- [x] DNS is fine: `localhost` resolves to `127.0.0.1` (the error says "connect", not "resolve", so DNS is not the problem)
- [x] Is anything listening on the port?
- [x] Is the process still running?
- [x] Did I use the right port?

Commands tried:
```bash
getent hosts localhost
# 127.0.0.1   localhost                      -> name resolution works

sudo ss -tulpn | grep 8081
# (no output)                                -> nothing is listening on 8081

ps aux | grep "http.server" | grep -v grep
# (no output)                                -> the server process is gone

jobs
# (empty)                                    -> I had stopped it with Ctrl+C in that terminal
```

## 4. Root Cause
"Connection refused" means the machine answered, but **no program was listening on that port**. I had closed the Python web server (Ctrl+C in the terminal), so port 8081 was no longer open.

## 5. Fix
```bash
cd ~/web
python3 -m http.server 8081 &        # start it again in the background
sudo ss -tulpn | grep 8081           # LISTEN ... python3
curl -i http://localhost:8081/       # HTTP/1.0 200 OK
```

## 6. Prevention / Lesson Learned
- **"Connection refused" = nothing listening** (service stopped, wrong port, or bound to another address). **"Timed out" = something is blocking** (firewall or Security Group). **"Could not resolve host" = DNS.** The wording tells me the layer.
- Check the port with `ss -tulpn` before blaming the network.
- A server bound to `127.0.0.1` can't be reached from another machine. Use `0.0.0.0` for all interfaces.
- For real services, use systemd (`systemctl status`) so they restart and I can read their logs.
- In scripts use `curl -f --max-time 10` so a failed request returns an exit code.

