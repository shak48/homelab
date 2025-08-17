
# Check Timer
  systemctl cat apt-daily.timer



/var/log/unattended-upgrades/unattended-upgrades.log

/var/log/apt/history.log

/var/log/apt/term.log


🔐 Fallback Root Password Setup
This task ensures that a root password is only set if one isn't already configured — perfect for VMs built from cloud-init templates where root access is disabled by default.

✅ Behavior:
If root has no password (e.g., ! or * in /etc/shadow) → A fallback password is set.

If root already has a valid password → Task is skipped safely.

📦 How it works:

- name: Set fallback root password only if it is unset or disabled
  ...
Reads /etc/shadow to detect locked root accounts

Uses chpasswd to apply fallback_root_password only when needed

Output is registered and displayed via a debug task

🔐 Variable Required:

fallback_root_password: "{{ vault_root_password }}"
Store this in a Vault-encrypted variable to keep it secure.