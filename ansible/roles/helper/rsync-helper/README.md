Role Name
=========

This role performs a secure, resumable file transfer using `rsync`, with live logging and optional async execution. Useful for syncing backup data across hosts (e.g. PVE to storage VM).

---

## Features

- Safe and resumable `rsync` (`--partial`, `--inplace`)
- Async execution to avoid playbook timeouts
- Real-time log output (`tee -a /var/log/rsync-transfer.log`)
- Auto-creates destination directory
- Optional fail-fast if source path doesn't exist

---

## Folder Structure

```
roles/
  rsync-transfer/
    tasks/
      main.yml
    defaults/
      main.yml
playbooks/
  rsync.yml
host_vars/
  pve-main.yml  # or pass vars via CLI
Requirements
------------



Role Variables
--------------

| Variable       | Description                     | Example Path                                      |
|----------------|----------------------------------|--------------------------------------------------|
| `rsync_src`    | Source directory                 | `/media/sandisk-4T/backups/...`                  |
| `rsync_dest`   | Destination directory            | `/mnt/share/`                                    |
| `rsync_log`    | Log file (default: `/tmp/...`)   | `/var/log/rsync-transfer.log`                    |

Set in playbook, CLI, or `host_vars`.

Dependencies
------------



Example Playbook
----------------

### Run on One Host (Override Variables)
```bash
ansible-playbook playbooks/rsync.yml \
  -l pve-main \
  -e "rsync_src=/media/sandisk-4T/backups/pve-main/rpool1/share/ \
       rsync_dest=/mnt/share/ \
       rsync_log=/var/log/rsync-transfer.log" \
  --ask-vault-pass
```

---

### Monitor Progress

On the target (`pve-main`):

```bash
sudo tail -f /var/log/rsync-transfer.log
```

---

### Output Location

- Transferred files: `{{ rsync_dest }}`
- Log file: `{{ rsync_log }}`

Author Information
------------------

An optional section for the role authors to include contact information, or a website (HTML is not allowed).
