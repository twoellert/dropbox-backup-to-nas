# Backup Dropbox to a mountable NAS directory
Usually you would periodically run this script via a cronjob.

## Pre-requisites
You need to be able to mount the NAS CIFS share and the Dropbox share onto the machine you run this script on. There are several manuals around on how to do that, just google it.

The file _dbxfs-config.json_ is generated in these manuals. This file with the necessary tools allow you to mount your dropbox into a local directory.

Needs the following binaries being available on the system:
```
# Binaries to call
BIN_MKDIR="/bin/mkdir"
BIN_MOUNTPOINT="/bin/mountpoint"
BIN_MOUNT="/bin/mount"
BIN_UMOUNT="/bin/umount"
BIN_EXPECT="/usr/bin/expect"
BIN_RSYNC="/usr/bin/rsync"
```

Check _config.sh_:
```
[...]

# Hostname of the NAS
NAS_HOSTNAME="your-nas.hostname"

# User credentials for mounting the NAS directory
USERNAME="nas-username"
PASSWORD="nas-password"

# Share on the NAS to mount
NAS_SHARE="path/to/your/nas/share"

[...]

# Dbxfs config file
DBXFS_CONFIG="/root/scripts/dbxfs-config.json"

# Dropbox refresh token password
DROPBOX_TOKEN="dropbox-token-password"

# Amount of backups to retain (running once per day, so keep a week worth of backups)
BACKUP_RETENTION=7

[...]
```

Main script to run is scripts/backup_run.sh.