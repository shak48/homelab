## Bootstrap Role — Ansible Usage (with `--check` mode)

This playbook bootstraps new machines by:

- Creating `ansible-user`
- Installing your public SSH key
- Adding user to `sudo` group with passwordless sudo
- Installing essential packages (`vim`, `curl`, `python3`, `tmux`)
- Setting the timezone

---

## SSH Key Generation for `ansible-user`

Generate a dedicated SSH key pair on your control node (Ansible machine):

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/ansible_id_rsa_ansible-user -C "ansible-user@control_node"

cp ~/.ssh/ansible_id_rsa_ansible-user.pub <project_directory>/roles/bootstrap/files/ansible_id_rsa.pub


---

### 🔍 Dry Run (Check Mode)

Use `--check` to preview what Ansible *would* do, without applying changes:

```bash
ansible-playbook playbooks/bootstrap.yml \
  -l pve_main \
  -u rumie \
  --private-key ~/.ssh/id_rsa \
  --ask-become-pass \
  --check

### Apply Changes for Real

  ansible-playbook playbooks/bootstrap.yml \
    -l pve_main \
    -u rumie \
    --private-key ~/.ssh/id_ed25519 \
    --ask-become-pass



###Run validation script

ansible-playbook playbooks/validate-bootstrap.yml -l pve_main


### TODO
-Take the variables out 