# 📁 Samba File Server Role (Ansible)

This role installs and configures a secure standalone Samba server on Linux. It supports individual per-user directories and an optional shared folder. Users and passwords are securely managed via Ansible Vault. The role is safe to re-run for credential changes or share adjustments.

## 🧩 Features

- Installs and configures the Samba server (`smbd`)
- Creates Linux system users (nologin shell)
- Adds Samba users securely (only if not already added)
- Creates and sets permissions for share directories
- Dynamically builds `smb.conf` from `samba_shares`
- Supports password and user management via Vault
- Prevents secrets from being logged (`no_log: true`)
- Automatically assigns ownership to prevent permission issues

## 🔐 Vault Setup

Create an encrypted file for passwords and users:

```bash
export EDITOR=nano
ansible-vault create group_vars/all/vault.yml
Paste into the vault file:


vault_root_password: "StrongFallbackPassword123!"

vault_samba_users:
  - name: user1
    password: "sambaUser1Secret"
  - name: user2
    password: "sambaUser2Secret"
Then in group_vars/all.yml:


samba_users: "{{ vault_samba_users }}"
🛠 Variables
In defaults/main.yml:


samba_users: "{{ vault_samba_users | default([]) }}"
samba_shares:
  - name: user1
    path: /srv/samba/user1
    valid_users: user1
  - name: user2
    path: /srv/samba/user2
    valid_users: user2
  - name: common
    path: /srv/samba/common
    valid_users: "user1, user2"
🔄 Safe Re-Runs & Idempotency
You can safely rerun this role:

Adds missing users (existing ones are not overwritten)

Updates passwords from Vault

Re-applies folder ownership

Does not delete or overwrite existing files in shared directories

🔐 Permission Handling
The role avoids access-denied issues by setting:


owner: "{{ item.valid_users.split(',')[0] | trim }}"
This assigns ownership of each shared folder to the first user in valid_users. This ensures Windows clients can access their assigned folders without needing manual chown. Permissions are recursively applied (recurse: true) and set to 0775 by default.

🚀 Usage
In your playbook:


- name: Configure Samba file server
  hosts: file-server
  become: true
  roles:
    - samba
Run it with:



ansible-playbook playbooks/create-file-server.yml --ask-vault-pass
Or using a saved vault password:


ansible-playbook playbooks/create-file-server.yml --vault-password-file ~/.vault_pass.txt
🧪 Windows Access Troubleshooting
To map a network drive from Windows:


net use Z: \\192.168.x.x\common /user:user1
If you see "Access Denied":

Make sure the folder path matches the share name

Confirm the user is in valid_users

Ensure file ownership matches the first valid_user

Restart Samba: sudo systemctl restart smbd

Clear saved credentials in Windows Credential Manager