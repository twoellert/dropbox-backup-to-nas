#!/bin/bash
# Ummount the dropbox directory
# You need to run "apt install cifs-utils" first

# Get script directory
SCRIPTDIR=$(dirname $(readlink -f $0))

# Include config
. ${SCRIPTDIR}/config.sh

echo "[INFO] Checking if dropbox has already been mounted <mountDir=$DROPBOX_MOUNT_DIR> ..."
if $BIN_MOUNTPOINT -q $DROPBOX_MOUNT_DIR; then
	echo "[INFO] Dropbox is mounted, unmounting it now ..."
	$BIN_UMOUNT $DROPBOX_MOUNT_DIR
	if [ $? -ne 0 ] ; then
		echo "[ERROR] Failed to unmount dropbox, aborting"
		exit 1
	fi
	echo "[INFO] Dropbox has been unmounted"
else
	# Call for unmount anyway
	$BIN_UMOUNT $DROPBOX_MOUNT_DIR
fi

exit 0
