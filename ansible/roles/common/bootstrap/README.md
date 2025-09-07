## Bootstrap Role — Ansible Usage (with `--check` mode)


Need to run as root.

This playbook bootstraps new machines by:

- Creating `ansible-user`
- Installing your public SSH key
- Adding user to `sudo` group with passwordless sudo
- Installing essential packages (`vim`, `curl`, `python3`, `tmux`)
- Setting the timezone

---

## SSH Key Generation for `ansible`

Generate a dedicated SSH key pair on your control node (Ansible machine):

###bash
Run this to create keys. must do this shenever changing machine
(../../../bash-scripts/ansible-control-node/bootstrap.sh)


---

### 🔍 Dry Run (Check Mode)

Use `--check` to preview what Ansible *would* do, without applying changes:

### bash
ansible-playbook playbooks/bootstrap.yml \
  -l pve_main \
  -u <local_user_name> \
  --private-key ~/.ssh/id_rsa \
  --ask-become-pass \
  --check

### Apply Changes for Real

  ansible-playbook playbooks/bootstrap.yml \
    -l pve-main \
    -u <local_user_name> \
    --ask-become-pass \
    --ask-vault-pass \



login issues:
Might need to manually insall sudo package.

# You will have to become root first
su -
# then install sudo
apt update
apt install sudo


###Run validation script

ansible-playbook playbooks/validate-bootstrap.yml -l pve_main


### TODO
-Take the variables out 