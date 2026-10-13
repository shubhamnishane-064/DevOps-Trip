# Notes: Day 6 - SSH 

**Week 1 | Saturday** | Topic: SSH, AWS key login, ssh config, scp, rsync

---

## 1. What is SSH?
- **SSH** = a safe way to **log in to another computer** (server) from my computer.
- Everything I type is **encrypted**, so nobody can read it on the network.
- Default **port 22**.
- Every cloud server (AWS EC2) is opened with SSH.

```bash
ssh username@server-ip
ssh ubuntu@13.233.10.20
```

---

## 2. Password vs Key login

| Password | Key (better) |
|---|---|
| Can be guessed | Very hard to break |
| I must type it | No typing, works in scripts |

**Key pair = 2 files**
- **Private key**: secret, stays on my laptop. Never share it.
- **Public key**: goes on the server. Safe to share.

Think of it like this: public key = the **lock**, private key = the **only key** that opens it.

---

## 3. AWS EC2 Key-Based Login

When I create an EC2 instance, AWS gives me a **key pair** and I download a `.pem` file (the private key).

**Steps**
1. AWS Console -> EC2 -> Launch instance.
2. Create a key pair (type `ed25519` or `RSA`), download `mykey.pem`.
3. Security Group: allow **SSH (port 22)** from **My IP** only.
4. Copy the instance **Public IPv4 address**.
5. Fix the key permission, then connect:

```bash
chmod 400 mykey.pem
ssh -i mykey.pem ubuntu@<public-ip>
```

| AWS image (AMI) | Username |
|---|---|
| Ubuntu | `ubuntu` |
| Amazon Linux | `ec2-user` |
| RHEL | `ec2-user` |
| Debian | `admin` |

Rules to remember
- `chmod 400` on the `.pem` file, or SSH says **UNPROTECTED PRIVATE KEY FILE**.
- Wrong username gives **Permission denied (publickey)**.
- Never upload the `.pem` file to GitHub.

---

## 4. Make my own key (for a normal server)

```bash
ssh-keygen -t ed25519          # press Enter for all questions
ssh-copy-id user@server-ip     # sends my public key to the server
ssh user@server-ip             # now logs in without a password
```
Files created in `~/.ssh/`:
- `id_ed25519` = private (secret)
- `id_ed25519.pub` = public (share)

**Permissions SSH needs**
```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 600 ~/.ssh/authorized_keys
```

---

## 5. SSH Config File (shortcut names)

Instead of typing the long command every time, save it in `~/.ssh/config`:

```
Host myec2
    HostName 13.233.10.20
    User ubuntu
    IdentityFile ~/.ssh/mykey.pem
```
```bash
chmod 600 ~/.ssh/config
ssh myec2                 # that's all
```

| Line | Meaning |
|---|---|
| `Host` | My short name |
| `HostName` | Server IP or DNS name |
| `User` | Login username |
| `IdentityFile` | Path to the private key |

---

## 6. scp (copy files with SSH)

Syntax: `scp  from  to`

```bash
# my laptop -> server
scp file.txt ubuntu@13.233.10.20:/home/ubuntu/

# server -> my laptop
scp ubuntu@13.233.10.20:/home/ubuntu/file.txt .

# a whole folder (-r)
scp -r myfolder ubuntu@13.233.10.20:/home/ubuntu/

# with a .pem key (-i) or my config name
scp -i mykey.pem file.txt ubuntu@13.233.10.20:/home/ubuntu/
scp file.txt myec2:/home/ubuntu/
```
Remember: the dot `.` means "this folder".

---

## 7. rsync (copy only what changed)

Faster than `scp` for repeated copies. It skips files that are already the same.

```bash
rsync -avz myfolder/ ubuntu@13.233.10.20:/home/ubuntu/myfolder/
rsync -avz -e "ssh -i mykey.pem" myfolder/ ubuntu@13.233.10.20:/home/ubuntu/myfolder/
rsync -avzn myfolder/ myec2:/home/ubuntu/myfolder/     # -n = test run, nothing copied
```

| Letter | Meaning |
|---|---|
| `a` | keep permissions, dates, folders |
| `v` | show what is happening |
| `z` | compress while sending |
| `n` | dry run (test first) |

| scp | rsync |
|---|---|
| Simple, copies everything | Copies only changes |
| Good for one file | Good for backups and big folders |

Slash tip: `myfolder/` copies the **contents**; `myfolder` copies the **folder itself**.

---

## 8. Basic SSH Commands (cheat sheet)

```bash
ssh user@ip                       # connect
ssh -i mykey.pem user@ip          # connect with a key file
ssh -p 2222 user@ip               # different port
ssh user@ip "df -h"               # run one command and come back
exit                              # leave the server

ssh-keygen -t ed25519             # create keys
ssh-copy-id user@ip               # install my public key
ssh -v user@ip                    # show details when it fails
ssh-keygen -R ip                  # remove an old fingerprint (server rebuilt)

scp file user@ip:/path/           # upload
scp user@ip:/path/file .          # download
rsync -avz src/ user@ip:/dest/    # sync a folder
```

---

## 9. Common SSH Errors

| Error | Meaning | Fix |
|---|---|---|
| `Permission denied (publickey)` | Wrong key, wrong user or bad permissions | Check username, `-i key`, `chmod 400/600` |
| `UNPROTECTED PRIVATE KEY FILE` | Key file too open | `chmod 400 mykey.pem` |
| `Connection timed out` | Blocked by firewall / Security Group, or wrong IP | Allow port 22 from my IP, check the IP |
| `Connection refused` | SSH service not running | `sudo systemctl start ssh` |
| `Host key verification failed` | Server was rebuilt | `ssh-keygen -R <ip>` |

---

## 10. Lab (Hands-on)

```bash
# 1. launch an EC2 (free tier), download mykey.pem
chmod 400 mykey.pem
ssh -i mykey.pem ubuntu@<public-ip>

# 2. add a shortcut
nano ~/.ssh/config          # Host myec2 ...
chmod 600 ~/.ssh/config
ssh myec2

# 3. copy a file up and down
echo "hello" > test.txt
scp test.txt myec2:/home/ubuntu/
scp myec2:/home/ubuntu/test.txt ./back.txt

# 4. sync a folder
rsync -avz myfolder/ myec2:/home/ubuntu/myfolder/
```
Stop the instance when done, so AWS does not charge me.

Result: (write what happened, add a screenshot. Hide the real IP.)

---

## 11. Errors Faced Today
- Example: `Permission denied (publickey)`
- Cause: key permissions too open / wrong username
- Fix: `chmod 400 mykey.pem` and use `ubuntu@` for Ubuntu

Full story: `troubleshooting/error-01.md`

---

## 12. Quick Q&A (for interviews)

**Q: What is SSH?**
A secure, encrypted way to log in to a remote server. Port 22.

**Q: Why keys instead of passwords?**
Keys are much harder to break and work in automation.

**Q: Which key goes on the server?**
The public key. The private key stays with me.

**Q: How do you connect to an EC2 instance?**
`chmod 400 key.pem` then `ssh -i key.pem ubuntu@<public-ip>`.

**Q: scp vs rsync?**
`scp` copies everything. `rsync` copies only the changes, so it is faster for repeated copies.

**Q: What do you do for `Permission denied (publickey)`?**
Check the username, the key path, and permissions, then run `ssh -v`.

---

## 13. Summary in 3 lines
1. SSH = secure remote login; use **keys**, not passwords.
2. For AWS: `chmod 400 key.pem`, then `ssh -i key.pem ubuntu@ip`; use `~/.ssh/config` for short names.
3. `scp` copies files, `rsync` copies only what changed.