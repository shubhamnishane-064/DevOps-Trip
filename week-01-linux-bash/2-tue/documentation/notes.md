# Notes: Day 2 - Processes, systemd and Logs

**Week 1 | Tuesday** | Topic: Process management, systemd services, journalctl logs

---

## 1. What is a Process?
- A **process** is a running program. Every process has a **PID** (process ID).
- Every process has a parent. The first process is **PID 1** (`systemd` on modern Linux).
- **Service / daemon** = a process that runs in the background (Nginx, SSH, Docker).

| Process state | Meaning |
|---|---|
| R | Running |
| S | Sleeping (waiting) |
| T | Stopped |
| Z | Zombie (finished, but parent has not cleaned it up) |

---

## 2. Viewing Processes

```bash
ps aux                  # all processes with details
ps aux | grep nginx     # find one program
ps -ef --forest         # show parent/child tree
top                     # live view (q to quit)
htop                    # nicer top (install if missing)
pidof nginx             # PID of a program
```

Useful columns in `ps aux`: **USER, PID, %CPU, %MEM, COMMAND**.

In `top`: press `M` to sort by memory, `P` to sort by CPU, `k` to kill, `q` to quit.

---

## 3. Stopping Processes (signals)

```bash
kill 1234          # polite stop (SIGTERM, signal 15)
kill -9 1234       # force stop (SIGKILL), last option only
pkill nginx        # kill by name
killall nginx      # kill all with that name
```

| Signal | Number | Meaning |
|---|---|---|
| SIGTERM | 15 | Ask the program to stop nicely (default) |
| SIGKILL | 9 | Force stop, no cleanup |
| SIGHUP | 1 | Reload config (used by some services) |

> Rule: try `kill` first, use `kill -9` only if it does not stop.

---

## 4. Foreground and Background Jobs

```bash
sleep 300 &        # run in background
jobs               # list my background jobs
fg %1              # bring job 1 to foreground
bg %1              # continue job 1 in background
Ctrl + C           # stop foreground program
Ctrl + Z           # pause foreground program
nohup ./script.sh &   # keep running after I close the terminal
```

---

## 5. systemd and systemctl (managing services)

**systemd** starts and manages services. We control it with `systemctl`.

```bash
systemctl status nginx       # is it running? last log lines
sudo systemctl start nginx   # start now
sudo systemctl stop nginx    # stop now
sudo systemctl restart nginx # stop + start
sudo systemctl reload nginx  # reload config, no downtime
sudo systemctl enable nginx  # start automatically at boot
sudo systemctl disable nginx # do not start at boot
systemctl is-active nginx    # prints active / inactive
systemctl list-units --type=service   # all services
systemctl --failed           # services that failed
```

| Term | Meaning |
|---|---|
| `start` / `stop` | Affects **now** only |
| `enable` / `disable` | Affects **next boot** only |
| `enable --now nginx` | Do both together |

Service files live in `/etc/systemd/system/` and `/lib/systemd/system/`.

### Simple custom service file
```ini
# /etc/systemd/system/myapp.service
[Unit]
Description=My Simple App
After=network.target

[Service]
ExecStart=/usr/bin/python3 /opt/myapp/app.py
Restart=always
User=devuser

[Install]
WantedBy=multi-user.target
```
```bash
sudo systemctl daemon-reload      # tell systemd about the new file
sudo systemctl enable --now myapp
```

---

## 6. Logs

Logs tell us **what happened and why**. This is the first place to look when something breaks.

| Location | What is inside |
|---|---|
| `/var/log/syslog` (Ubuntu) / `/var/log/messages` (RHEL) | General system messages |
| `/var/log/auth.log` (Ubuntu) / `/var/log/secure` (RHEL) | Logins, sudo, SSH |
| `/var/log/nginx/error.log` | Nginx errors |
| `/var/log/dmesg` or `dmesg` | Kernel and hardware messages |

### journalctl (systemd logs)
```bash
journalctl -u nginx              # logs of one service
journalctl -u nginx -f           # follow live
journalctl -u nginx -n 50        # last 50 lines
journalctl -u nginx --since "10 min ago"
journalctl -p err -b             # only errors since last boot
journalctl --disk-usage          # how much space logs use
```

### Reading text logs
```bash
tail -n 50 /var/log/syslog
tail -f /var/log/nginx/error.log
grep -i "error" /var/log/syslog
grep -i "failed" /var/log/auth.log
```

---

## 7. Lab (Hands-on)

**Goal:** install Nginx, break it on purpose, find the cause in the logs and fix it.

```bash
sudo apt update
sudo apt install nginx -y
sudo systemctl enable --now nginx
systemctl status nginx
curl http://localhost                # should show the Nginx welcome page

# break it on purpose
sudo nano /etc/nginx/sites-enabled/default   # add a typo, e.g. remove a ';'
sudo nginx -t                                 # test config: shows the error line
sudo systemctl restart nginx                  # fails
systemctl status nginx
journalctl -u nginx -n 20                     # read the reason

# fix it
sudo nano /etc/nginx/sites-enabled/default   # put the ';' back
sudo nginx -t                                 # syntax is ok
sudo systemctl restart nginx
curl http://localhost
```

Result: (write what happened here, add a screenshot)

---

## 8. Errors Faced Today
- Example: `Job for nginx.service failed because the control process exited with error code`
- Cause: typo in the Nginx config file (missing `;`)
- Fix: found the line with `nginx -t` and `journalctl -u nginx`, corrected it, restarted

Write the full story in `troubleshooting/error-01.md`.

---

## 9. Quick Q&A (for interviews)

**Q: What is a process?**
A running program with a PID.

**Q: Difference between a process and a service?**
A service (daemon) is a process that runs in the background and is managed by systemd.

**Q: How do you find which process is using port 80?**
`sudo ss -tulpn | grep :80` (or `sudo lsof -i :80`).

**Q: `kill` vs `kill -9`?**
`kill` asks the program to stop (SIGTERM). `kill -9` forces it (SIGKILL) with no cleanup.

**Q: `start` vs `enable`?**
`start` runs it now. `enable` makes it start at boot.

**Q: A service failed. What do you do?**
`systemctl status <name>`, then `journalctl -u <name> -n 50`, find the error, fix it, restart.

**Q: What is a zombie process?**
A finished process whose parent has not collected its exit status yet.

---

## 10. Summary in 3 lines
1. A process is a running program; `ps`, `top` and `kill` manage them.
2. `systemctl` starts, stops and enables services; `enable` means start at boot.
3. When something breaks, read the logs: `journalctl -u <service>` and `/var/log`.