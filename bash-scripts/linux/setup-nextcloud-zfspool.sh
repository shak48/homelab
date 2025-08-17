


# parent for everything Nextcloud
zfs create -o mountpoint=/tankmirror/nc/nc1 \
           -o compression=zstd \
           -o atime=off 
           -o xattr=sa \
           -o acltype=posixacl \
           tankmirror/nc/nc1

# sub-datasets (optional but nice for tuning/quotas)
zfs create -o recordsize=128K tankmirror/nc/nc1/data
zfs create -o recordsize=16K  tankmirror/nc/nc1/db
zfs create                    tankmirror/nc/nc1/html

# (optional) cap size so NC can’t eat the whole pool
zfs set quota=64G tankmirror/nc/nc1
