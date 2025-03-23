#!/bin/bash
# Common config for scripts

# Hostname of the NAS
NAS_HOSTNAME="your-nas.hostname"

# User credentials for mounting the NAS directory
USERNAME="nas-username"
PASSWORD="nas-password"

# Share on the NAS to mount
NAS_SHARE="path/to/your/nas/share"

# Temporary NAS directory to mount to
NAS_MOUNT_DIR="/root/dropbox/mnt-nas"

# Temporary Dropbox directory to mount to
DROPBOX_MOUNT_DIR="/root/dropbox/mnt-dropbox"

# Dbxfs config file
DBXFS_CONFIG="/root/scripts/dbxfs-config.json"

# Dropbox refresh token password
DROPBOX_TOKEN="dropbox-token-password"

# Amount of backups to retain (running once per day, so keep a week worth of backups)
BACKUP_RETENTION=7

# Binaries to call
BIN_MKDIR="/bin/mkdir"
BIN_MOUNTPOINT="/bin/mountpoint"
BIN_MOUNT="/bin/mount"
BIN_UMOUNT="/bin/umount"
BIN_EXPECT="/usr/bin/expect"
BIN_RSYNC="/usr/bin/rsync"
