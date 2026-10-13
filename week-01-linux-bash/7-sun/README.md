
# Linux & Bash Foundations | Week 1 - Sunday: Mega Project

**Date:** 3 oct 2026|  **Time spent:** 4-5 hrs  |  **Status:** [x] Done

## Today's Goal
Combine everything from Week 1 into one project that I can show to recruiters: a **Server Health & Backup Toolkit**.

## Plan (checklist)
- [x] Plan the design (runner + config + helper scripts)
- [x] Build `toolkit.sh`, `toolkit.conf` and `install.sh`
- [x] Reuse `healthcheck.sh`, `temperature.sh`, `backup.sh`
- [x] Test normal and failure cases
- [x] Write the project README with a diagram
- [x] Write notes and one error log


## What I Did
- Built a main runner (`toolkit.sh`) that reads `toolkit.conf` and runs the health check, temperature check and backup.
- Logged every step with a timestamp in `toolkit.log` and returned exit code 0 (good) or 1 (problem).
- Wrote `install.sh` to add and remove cron jobs without creating duplicates.
- Tested: normal run, missing backup folder, high disk usage, a stopped service, and a restore from backup.
- Wrote the project README with architecture diagram, usage, sample output and future improvements.

## Project
Go to the project folder: [`mega-project/`](mega-project/README.md)

| File | What it does |
|---|---|
| [`src/toolkit.sh`](mega-project/src/toolkit.sh) | Main runner (`health`, `temp`, `backup`, `all`) |
| [`src/toolkit.conf`](mega-project/src/toolkit.conf) | Settings |
| [`src/healthcheck.sh`](mega-project/src/healthcheck.sh) | CPU load, memory, disk, processes, services |
| [`src/temperature.sh`](mega-project/src/temperature.sh) | Temperature check |
| [`src/backup.sh`](mega-project/src/backup.sh) | Dated backup + cleanup |
| [`src/install.sh`](mega-project/src/install.sh) | Cron installer |

## Lab Summary
```bash
cd mega-project/src
chmod +x *.sh
./toolkit.sh
echo $?                    # 0 = all good
./install.sh --install
crontab -l
```

## What I Learned
- A project is notes + working code + a README + tests + error logs.
- Config files keep settings out of the code (and need no spaces around `=`).
- Exit codes let scripts talk to cron, CI and monitoring tools.
- Test the failure cases, not only the working one.

## Notes
Full notes: [`documentation/notes.md`](documentation/notes.md)

## Next Week
Week 2: Networking for DevOps (TCP/IP, DNS, HTTP, Nginx reverse proxy and load balancer).