# Error Log: Nginx failed to start after config change

**Date:** 2026-09-29  |  **Day:** Week 1 Tuesday  |  **Severity:** Medium

## 1. Symptom (what I saw)
```
$ sudo systemctl restart nginx
Job for nginx.service failed because the control process exited with error code.
See "systemctl status nginx.service" and "journalctl -xeu nginx.service" for details.
```

## 2. Context (what I was doing)
I installed Nginx, confirmed the welcome page worked with `curl http://localhost`, then edited `/etc/nginx/sites-enabled/default` to practise reading logs. After my edit I restarted Nginx.

## 3. Investigation (how I debugged)
- [x] Read the error: it points me to `systemctl status` and `journalctl`
- [x] Checked logs
- [x] Tested the config syntax
- [x] Reproduced it (the restart failed every time until fixed)

Commands tried:
```bash
systemctl status nginx
# Active: failed (Result: exit-code)

journalctl -u nginx -n 20
# nginx: [emerg] unexpected "}" in /etc/nginx/sites-enabled/default:22
# nginx: configuration file /etc/nginx/nginx.conf test failed

sudo nginx -t
# nginx: [emerg] unexpected "}" in /etc/nginx/sites-enabled/default:22
```

## 4. Root Cause
I removed a `;` at the end of a directive. Nginx requires every directive to end with `;`, so it hit an unexpected `}` and refused to start. The line number in the error was the line after the real mistake.

## 5. Fix
```bash
sudo nano /etc/nginx/sites-enabled/default   # put the ';' back on the line above line 22
sudo nginx -t
# syntax is ok / test is successful
sudo systemctl restart nginx
systemctl is-active nginx    # active
curl http://localhost        # Nginx welcome page
```

## 6. Prevention / Lesson Learned
- Always run `sudo nginx -t` **before** restarting or reloading.
- Use `reload` instead of `restart` when possible, so a bad config does not take the site down.
- The error line number can point to the line after the real problem.
- Make a backup first: `sudo cp default default.bak`.

## 7. References
- `man systemctl`, `man journalctl`
- Day 2 notes: `../documentation/notes.md`, sections 5 and 6