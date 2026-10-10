# Linux & Bash Foundations | Week 1 - Tuesday: Processes, systemd, logs

**Date:** 2026-09-29|  **Time spent:** 2-3 hrs  |  **Status:** [x] Done

## Today's Goal
Learn how to view and control processes, manage services with systemd, and find problems using logs.

## Plan (checklist)
- [x] Learn the concept (processes, signals, systemd, journalctl)
- [x] Hands-on lab: install Nginx, break it on purpose, fix it using logs
- [x] Write notes in `documentation/`
- [x] Log one error in `troubleshooting/`
- [x] Commit and push with a clear message

## What I Did
- Studied processes and PIDs, and how a service differs from a normal process.
- Practised `ps aux`, `top`, `pidof`, `kill`, `kill -9`, `pkill` and background jobs (`&`, `jobs`, `fg`, `bg`, `nohup`).
- Managed services with `systemctl`: `start`, `stop`, `restart`, `reload`, `enable`, `disable`, `status`.
- Wrote a simple custom systemd service file and loaded it with `daemon-reload`.
- Read logs with `journalctl -u <service>`, `/var/log/syslog`, `/var/log/auth.log`, `tail -f` and `grep`.

## Lab Summary
```bash
sudo apt install nginx -y
sudo systemctl enable --now nginx
curl http://localhost                 # welcome page
# broke the config (removed a ';')
sudo nginx -t                         # showed the error line
sudo systemctl restart nginx          # failed
journalctl -u nginx -n 20             # found the reason
# fixed the config, restarted, curl worked again
```
Result: Nginx failed with an exit-code error until I restored the missing `;`. (Add a screenshot in `documentation/images/`.)

## What I Learned
- `start` runs a service now; `enable` makes it start at boot.
- `kill` asks nicely (SIGTERM); `kill -9` forces (SIGKILL), so use it last.
- `systemctl status` then `journalctl -u <service>` is my first debugging path.
- `nginx -t` checks the config before I restart anything.

## Errors Faced
- `Job for nginx.service failed`: see [`troubleshooting/error-01.md`](troubleshooting/error-01.md)

## Notes
Full notes: [`documentation/notes.md`](documentation/notes.md)

## Tomorrow
Day 3: package management (`apt`, `dnf`), cron jobs, disk and memory (`df`, `du`, `free`).