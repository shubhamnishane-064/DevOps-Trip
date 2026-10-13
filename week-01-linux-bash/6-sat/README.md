# Linux & Bash Foundations | Week 1 - Saturday: SSH, AWS key login, scp and rsync

**Date:** 03-10-2026 |  **Time spent:** 2-3 hrs  |  **Status:** [x] Done

## Today's Goal
Log in to a server safely with SSH keys (AWS EC2), use shortcut names, and copy files with `scp` and `rsync`.

## Plan (checklist)
- [x] Learn the concept (SSH, private and public key)
- [x] Hands-on lab: launch EC2, connect with a `.pem` key
- [x] Create an SSH config shortcut
- [x] Copy files with `scp` and `rsync`
- [x] Write notes in `documentation/`
- [x] Log one error in `troubleshooting/`


## What I Did
- Learned that SSH is an encrypted way to log in to a remote server (port 22).
- Learned password login vs key login, and the private key (secret) vs public key (shared).
- Launched a free-tier EC2 instance, downloaded the `.pem` key, set `chmod 400`, and connected with `ssh -i mykey.pem ubuntu@<ip>`.
- Created `~/.ssh/config` so I can connect with just `ssh myec2`.
- Uploaded and downloaded files with `scp` (also a folder with `-r`).
- Synced a folder with `rsync -avz` and tested it first with a dry run (`-n`).
- Stopped the instance afterwards to avoid charges.

## Lab Summary
```bash
chmod 400 mykey.pem
ssh -i mykey.pem ubuntu@<public-ip>

# ~/.ssh/config
# Host myec2
#     HostName <public-ip>
#     User ubuntu
#     IdentityFile ~/.ssh/mykey.pem
ssh myec2

echo "hello" > test.txt
scp test.txt myec2:/home/ubuntu/
scp myec2:/home/ubuntu/test.txt ./back.txt
rsync -avz myfolder/ myec2:/home/ubuntu/myfolder/
```
Result: login with the key worked, the file was uploaded and downloaded, and the folder was synced. (Add a screenshot in `documentation/images/`. Hide the real IP.)

## What I Learned
- Private key stays with me; public key goes on the server.
- `.pem` files need `chmod 400`, or SSH refuses them.
- Ubuntu servers use the user `ubuntu`; Amazon Linux uses `ec2-user`.
- `~/.ssh/config` turns a long command into `ssh myec2`.
- `scp` copies everything; `rsync` copies only the changes.
- The Security Group must allow port 22 from my IP.

## Errors Faced
- `Permission denied (publickey)` (key file too open): see [`troubleshooting/error-01.md`](troubleshooting/error-01.md)

## Notes
Full notes: [`documentation/notes.md`](documentation/notes.md)

## Optional (later)
[`ssh_audit.sh`](ssh_audit.sh) checks SSH hardening settings on a server. It is extra practice, not needed for today.

## Tomorrow
Day 7 (Sunday): mega project - server health-check and backup toolkit (combine `healthcheck.sh`, `backup.sh`, cron, README, screenshots).