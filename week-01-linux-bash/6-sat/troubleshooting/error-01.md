# Error Log: Permission denied (publickey) when connecting to AWS EC2

**Date:** 03-10-2026  |  **Day:** Week 1 Saturday  |  **Severity:** Medium (could not log in)

## 1. Symptom (what I saw)
First I saw this warning:
```
$ ssh -i mykey.pem ubuntu@13.233.10.20
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@         WARNING: UNPROTECTED PRIVATE KEY FILE!          @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
Permissions 0644 for 'mykey.pem' are too open.
ubuntu@13.233.10.20: Permission denied (publickey).
```

## 2. Context (what I was doing)
I launched a free-tier EC2 instance, downloaded `mykey.pem`, and tried to connect from my laptop.

## 3. Investigation (how I debugged)
- [x] Read the message: the key file is "too open"
- [x] Checked the key file permissions
- [x] Checked the username for the AMI (Ubuntu = `ubuntu`)
- [x] Ran SSH in verbose mode

Commands tried:
```bash
ls -l mykey.pem
# -rw-r--r-- 1 shubham shubham 1675  mykey.pem     -> others can read it (644)

ssh -v -i mykey.pem ubuntu@13.233.10.20
# debug1: Offering public key: mykey.pem
# Permission denied (publickey)                           -> key was refused
```

## 4. Root Cause
SSH refuses a private key that other users can read. My `.pem` file had permission `644`, so SSH ignored it and the login failed.

## 5. Fix
```bash
chmod 400 mykey.pem
ls -l mykey.pem
# -r-------- 1 shubham shubham 1675 mykey.pem     -> only I can read it

ssh -i mykey.pem ubuntu@13.233.10.20
# Welcome to Ubuntu ...                                   -> logged in
```

## 6. Other causes of the same error (checklist)
| Cause | Check / fix |
|---|---|
| Wrong username | Ubuntu = `ubuntu`, Amazon Linux = `ec2-user` |
| Wrong key file | The `.pem` must be the one chosen when launching the instance |
| Key too open | `chmod 400 mykey.pem` |
| Wrong IP | The public IP changes after stop/start (use an Elastic IP if needed) |
| Timeout instead of denied | Security Group must allow port 22 from my IP |

## 7. Prevention / Lesson Learned
- Run `chmod 400` on every new `.pem` file straight after download.
- Check the username for the AMI before connecting.
- Use `ssh -v` to see which key is offered and why it fails.
- Save the settings in `~/.ssh/config` so I do not mistype them:
  ```
  Host myec2
      HostName 13.233.10.20
      User ubuntu
      IdentityFile ~/.ssh/mykey.pem
  ```
- Never upload the `.pem` file to GitHub. Add `*.pem` to `.gitignore`.
