#!/bin/bash
# Ummount the backup directory from the NAS
# You need to run "apt install cifs-utils" first

# Get script directory
SCRIPTDIR=$(dirname $(readlink -f $0))

# Include config
. ${SCRIPTDIR}/config.sh

echo "[INFO] Checking if share has already been mounted <host=$NAS_HOSTNAME><share=$NAS_SHARE><mountDir=$NAS_MOUNT_DIR> ..."
if $BIN_MOUNTPOINT -q $NAS_MOUNT_DIR; then
	echo "[INFO] Share is mounted, unmounting it now ..."
	$BIN_UMOUNT $NAS_MOUNT_DIR
	if [ $? -ne 0 ] ; then
		echo "[ERROR] Failed to unmount share, aborting"
		exit 1
	fi
	echo "[INFO] Share has been unmounted"
else
	# Call for unmount anyway
	$BIN_UMOUNT $NAS_MOUNT_DIR
fi

exit 0
