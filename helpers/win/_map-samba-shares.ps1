# Clear any old connections
net use * /delete /y

# Map Common with a Samba user (recommended)
net use Z: \\<server-ip>\Common /user:smbuser <password> /persistent:yes

# Map private share
net use Y: \\<server-ip>\Shahriar /user:shahriar <password> /persistent:yes
