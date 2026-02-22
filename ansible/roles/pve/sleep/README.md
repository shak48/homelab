# roles/pve/sleep/README.md

## What this role does
- Deploys `/usr/local/bin/suspend.sh` and `/usr/local/bin/poweroff.sh`
- Schedules:
  - Suspend daily at `sleep_suspend_cron_hour:sleep_suspend_cron_minute`
  - Poweroff daily at `sleep_poweroff_cron_hour:sleep_poweroff_cron_minute`
- Logs to:
  - `/var/log/suspend-wake.log`
  - `/var/log/poweroff-wake.log`

## Quick status checks
```bash
sudo crontab -l -u root
sudo tail -n 50 /var/log/suspend-wake.log
sudo tail -n 50 /var/log/poweroff-wake.log
```

## RTC alarm sanity checks (no shutdown)
```bash
sudo rtcwake -m show
sudo rtcwake -m no -s 120
cat /sys/class/rtc/rtc0/wakealarm
```

## One-shot test modes (safe)
Suspend after 60s, wake 60s later:
```bash
sudo WAKE_SECONDS_OVERRIDE=120 DELAY_SECONDS_OVERRIDE=60 /usr/local/bin/suspend.sh
```

Poweroff after 120s, wake 120s later (needs BIOS RTC wake):
```bash
sudo WAKE_SECONDS_OVERRIDE=240 DELAY_SECONDS_OVERRIDE=120 /usr/local/bin/poweroff.sh
```

## Common issues and fixes
### Poweroff does not wake
- The OS is setting the RTC alarm correctly, but the machine stays off.
- Check BIOS/UEFI for:
  - `Wake on RTC`
  - `Resume by Alarm`
  - `Power On By RTC`

### No recent log entries
- If the machine is powered off when cron should run, the job is missed.
- Confirm cron entries exist and the host is up at the scheduled time.

### Time looks off in logs
- `rtcwake` reports wake times in UTC.
- Script logs include both local time and UTC time.

## Related variables (defaults)
- `sleep_suspend_wake_hours`
- `sleep_poweroff_wake_hours`
- `sleep_suspend_timer_seconds`
- `sleep_poweroff_timer_seconds`
- `sleep_rtc_offset_hours` (0 if RTC is already UTC)
