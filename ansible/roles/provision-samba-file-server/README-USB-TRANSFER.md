Recommended workflow (PVE host)
Mount removable drive with correct driver (ntfs-3g, exfat, etc.)


lsblk -f   # find your device, e.g. /dev/sde1
umount /dev/sde1 2>/dev/null || true
mkdir -p /mnt/usb
mount -t ntfs-3g -o rw,uid=0,gid=0,umask=022,big_writes,windows_names /dev/sde1 /mnt/usb
Mount Samba share through CIFS

mkdir -p /mnt/smb-tahia
mount -t cifs //samba-server/Tahia /mnt/smb-tahia -o guest,vers=3.0
# Or, with credentials:
# mount -t cifs //samba-server/Tahia /mnt/smb-tahia -o username=smbuser,password='yourpass',vers=3.0
Copy files through Samba mount

rsync -avh --info=progress2 /mnt/usb/ /mnt/smb-tahia/
Unmount when done

umount /mnt/usb
umount /mnt/smb-tahia
Automation script (copy-usb-to-samba.sh)
#!/bin/bash
set -e

USB_DEV="${1:-/dev/sde1}"   # Device for removable media
USB_MNT="/mnt/usb"
SMB_MNT="/mnt/smb-tahia"
SMB_PATH="//samba-server/Tahia"
SMB_OPTS="guest,vers=3.0"
# SMB_OPTS="username=smbuser,password='yourpass',vers=3.0"

echo "[*] Mounting USB drive $USB_DEV..."
umount "$USB_DEV" 2>/dev/null || true
mkdir -p "$USB_MNT"
mount -t ntfs-3g -o rw,uid=0,gid=0,umask=022,big_writes,windows_names "$USB_DEV" "$USB_MNT"

echo "[*] Mounting Samba share $SMB_PATH..."
umount "$SMB_MNT" 2>/dev/null || true
mkdir -p "$SMB_MNT"
mount -t cifs "$SMB_PATH" "$SMB_MNT" -o $SMB_OPTS

echo "[*] Copying files from USB to Samba share..."
rsync -avh --info=progress2 "$USB_MNT"/ "$SMB_MNT"/

echo "[*] Unmounting..."
umount "$USB_MNT"
umount "$SMB_MNT"

echo "[+] Copy complete."
chmod +x copy-usb-to-samba.sh
./copy-usb-to-samba.sh /dev/sde1