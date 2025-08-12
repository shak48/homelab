# ansible-playbook playbooks/provision-samba-file-server.yml 


# syntax & effective config
testparm -s

# service status & logs
systemctl status smbd
journalctl -u smbd --since "10 min ago"

# ports
ss -tlnp | grep -E ':(139|445)\s'

# shares visible from server
smbclient -L //127.0.0.1 -N

# list the Common share
smbclient //127.0.0.1/Common -N -c 'ls'

# check permissions on the directories
ls -ld /mnt/share /mnt/share/Common /mnt/share/Shahriar /mnt/share/Tahia

# if using ufw
ufw status




# allow guest logons (persist)
Set-SmbClientConfiguration -EnableInsecureGuestLogons $true -Force
Get-SmbClientConfiguration | Select EnableInsecureGuestLogons

# test TCP/445 reachability
Test-NetConnection -ComputerName 192.168.10.120 -Port 445

# map the share as Guest (no password)
net use * /delete /y
net use \\192.168.10.120\Common "" /user:Guest /persistent:yes

# list shares the client sees
net view \\192.168.10.120





# Show merged vars for this host
ansible-inventory -i inventory/hosts.ini --host samba-server --vars

# Or quick ad-hoc debug:
ansible -i inventory/hosts.ini samba-server -m debug -a "var=samba_guest_shares"
ansible -i inventory/hosts.ini samba-server -m debug -a "var=samba_guest_user"






#Copyfiles:

sudo rsync -ah --info=progress2 --stats /src/ /dst/
