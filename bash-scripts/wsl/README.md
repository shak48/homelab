### `bootstrap-control-node.sh`

This script generates a dedicated ED25519 SSH key for use by Ansible (`id_ansible_ed25519`) in the current user’s `~/.ssh` directory. It also archives any existing keypair with a timestamp in `~/.ssh/old-keys/`.

#### ✅ Usage

Run as your regular user (not root):

```bash
./bash-scripts/bootstrap-control-node.sh
```

To override defaults:

```bash
KEY_NAME=mykey KEY_COMMENT="control@$(hostname -s)" ./bash-scripts/bootstrap-control-node.sh
```

#### 🔧 Variables (optional)

| Variable     | Default                         | Purpose                          |
|--------------|----------------------------------|----------------------------------|
| `KEY_NAME`   | `id_ansible_ed25519`             | SSH key file name (no extension) |
| `KEY_COMMENT`| `ansible@<hostname>`             | SSH key comment                  |
| `ARCHIVE_DIR`| `~/.ssh/old-keys`                | Directory for archiving old keys |

---

### ⚠️ Common Issues & Mistakes

#### 1. **Key ends up in `/root/.ssh/`**

**Mistake**: Running the script with `sudo`:
```bash
sudo ./bootstrap-control-node.sh
```

**Fix**: Run as a normal user instead:
```bash
./bootstrap-control-node.sh
```

#### 2. **Ansible looks for a stale key**

**Mistake**: You copied an old `.pub` file to the repo and forgot it was outdated.

**Fix**: Let Ansible read the public key from your current `~/.ssh/` instead. This is already handled in the playbook:
```yaml
key: "{{ lookup('file', lookup('env', 'HOME') + '/.ssh/id_ansible_ed25519.pub') }}"
```

#### 3. **Wrong `~` when using `sudo`**

**Mistake**: Assuming `~/.ssh` refers to your home when using `sudo`. In fact:
```bash
sudo anything...
```
will treat `~` as `/root`.

**Fix**: Avoid `sudo` unless explicitly required.
