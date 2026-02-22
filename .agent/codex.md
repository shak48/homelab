## Progress Log

### 2026-02-22
- Step 1 complete: Inventory & vars consistency audit.
- Findings:
  - Undefined inventory groups referenced: `pve-servers`, `pve-lan`, `pve-main`, `pve_servers`, `print_servers`.
  - Hostname mismatch: inventory `pve1-test` vs host vars `pve-test1.yml`.
  - Missing vars file: `ansible/playbooks/pve/install_test_pve.yml` references `../vars.yml`.
  - Wrong vars path: `ansible/playbooks/vm/create-print-server.yml` points to `roles/print-server/vars/main.yml` but actual is `roles/vm/print-server/vars/main.yml`.
  - Missing roles: `check-basics`, `npm_selfcert`, `npm_compose`.
  - Likely undefined non‑vault vars: `iso_dir`, `proxmox_iso_dir`, `npm_admin_email`, `npm_admin_password`, `npm_cert_cn`, `minecraft_memory`, `scanservjs_port`.
  - Vault-backed vars referenced and expected (e.g., `vault_root_password`, `vault_default_user`, `vault_samba_users`).

- Step 2 complete: Playbook execution flow audit.
- Findings:
  - Multiple playbooks reference missing inventory groups: `pve-servers`, `pve-lan`, `pve-main`, `pve_servers`, `print_servers`.
  - `bootstrap`/`harden` notify `Restart sshd` but handlers missing; `error_on_missing_handler=True` makes `bootstrap-all` fail.
  - `update-host-file.yml` has invalid ping command.
  - `install_test_pve.yml` references missing `../vars.yml`.
  - `create-print-server.yml` references wrong vars path.
  - `provision-nginx-rpm.yml` references missing roles `npm_selfcert`, `npm_compose`.
  - `check-basics` role missing.
  - `provision-vm` uses mismatched variable names for cores/memory.
  - `provision-vm-nc` copies a Jinja template as raw file (vars won’t render).
  - `immich-docker` doesn’t deploy containers (only Samba mount).
  - `provision-vm-docker` only runs RustDesk tasks; Docker install and other services are commented.
  - `create-workstation-ubuntu` references missing `install-rustdesk-agent.yml` subtask.
  - `provision-samba-file-server` has empty `packages.yml` and `shares.yml`.

- Step 3 complete: Role-level behavior audit.
- Findings:
  - `roles/common/common-role` empty; handler exists but unused.
  - `roles/common/common-docker-role` adds literal `remote_user` to docker group (likely wrong user).
  - `roles/common/bootstrap` and `roles/common/harden` notify `Restart sshd` without handlers.
  - `roles/pve/upgrade-to-pve9` has PVE no‑subscription repo commented out.
  - `roles/vm/provision-vm-workstattion` broken (typo role name, missing `set-facts.yml`, wrong variable `target_hosts`).
  - `roles/vm/create-vm-template` expects `pve_servers` group and missing SSH key file.
  - `roles/vm/create-workstation-ubuntu` includes missing task file `install-rustdesk-agent.yml`.
  - `roles/vm/provision-vm-docker` only runs RustDesk; Docker install and other stacks commented out.
  - `roles/vm/provision-vm-docker/templates/adguard-docker-compose.yml.j2` has invalid port syntax.
  - `roles/vm/provision-vm-nc` copies compose without templating; includes secrets in `files/working-config.php`.
  - `roles/vm/provision-samba-file-server` has empty `packages.yml` and `shares.yml`; `smb.conf.j2` malformed.
  - `roles/vm/immich-docker` doesn’t deploy containers; template path is wrong; `.env` has hardcoded password.
  - `roles/vm/install-rustdesk-agent` runs `dpkg -i` twice; RustDesk config template has syntax error and is not deployed.
  - `roles/vm/provision-vm-nginx` needs `community.crypto` but requirements missing.

- Step 4 complete: Service architecture map and dependency wiring.
- Findings:
  - OPNsense role is empty (no automation for gateway VM).
  - Nextcloud wiring: ZFS role OK; compose deployment won’t render secrets.
  - Immich wiring: Samba mount OK; docker stack not wired.
  - Samba wiring: package install and shares not wired.
  - Docker host wiring: only RustDesk active; other stacks inert.

- Step 5 complete: Prioritized fix list (no changes applied).
- Findings:
  - Must-fix: inventory group mismatches, missing handlers, missing roles, malformed templates, secrets in repo.
  - Important: var name mismatches, missing collections, docker install flow, immich deployment wiring, samba tasks.
  - Cleanup: role naming/path consistency, placeholder tests, duplicate tasks.

- Sleep role debug (pve):
  - Verified `/usr/local/bin/suspend.sh` and `/usr/local/bin/poweroff.sh` exist and match role defaults (7h suspend wake, 10h poweroff wake; delays 60s/300s).
  - Could not read root crontab or log files due to lack of sudo on `rumie@192.168.10.111`.
  - User provided logs:
    - `suspend-wake.log` shows WAKE_HOURS=8 on Dec 26/29, 2025.
    - `poweroff-wake.log` shows WAKE_HOURS=8 on Feb 14/15, 2026; WAKE_HOURS=10 on Feb 17, 2026.
  - Root crontab (user-provided): suspend Mon–Fri 08:05; poweroff daily 22:00 with `WAKE_HOURS=10`.
  - Suspected issue: RTC wake offset due to RTC/UTC mismatch (rtcwake assumes UTC).
  - Change applied: added `sleep_rtc_offset_hours` in `roles/pve/sleep/defaults/main.yml` (now set to 0).
  - Change applied: updated `suspend.sh.j2` and `poweroff.sh.j2` to apply offset via explicit default handling.
  - Deployed updated scripts to `pve` via `ansible-playbook playbooks/pve/sleep.yml -l pve` (2 changes).
  - Change applied: removed `WAKE_HOURS` override from cron, added status task, added UTC log line in scripts.
  - Change applied: set `sleep_rtc_offset_hours` to 0 and `sleep_suspend_timer_seconds` to 300.
  - Change pending: add poweroff test mode via `WAKE_SECONDS_OVERRIDE` and `DELAY_SECONDS_OVERRIDE`.
  - Change applied: add suspend test mode via `WAKE_SECONDS_OVERRIDE` and `DELAY_SECONDS_OVERRIDE`.
  - Change pending: set suspend cron to run daily (weekdays + weekends).
  - Change applied: set suspend cron to run daily (0-6) and deployed to `pve`.
  - Change applied: expanded `roles/pve/sleep/README.md` with troubleshooting and test steps.
