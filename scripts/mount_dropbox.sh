#!/bin/bash
# Mount the atmosphere dropbox
# You need to run the following commands first as given in this manual: https://itsubuntu.com/mount-dropbox-folder-locally-linux/
# Also you need to install expect via "dnf install expect"

# Get script directory
SCRIPTDIR=$(dirname $(readlink -f $0))

# Include config
. ${SCRIPTDIR}/config.sh

echo "[INFO] Checking if temporary mount directory exists <mountDir=$DROPBOX_MOUNT_DIR> ..."
if [ ! -d $DROPBOX_MOUNT_DIR ] ; then
	echo "[INFO] Temporary directory does not exist, creating it"
	OUT=`$BIN_MKDIR -p $DROPBOX_MOUNT_DIR`
	if [ $? -ne 0 ] ; then
		echo "[ERROR] Failed to create temporary mount directory, aborting"
		exit 1
	fi
fi

echo "[INFO] Checking if dropbox has already been mounted <mountDir=$DROPBOX_MOUNT_DIR> ..."
if $BIN_MOUNTPOINT -q $DROPBOX_MOUNT_DIR; then
	echo "[INFO] Dropbox is already mounted ..."
else
	echo "[INFO] Dropbox is not mounted, mounting it now ..."
	$BIN_EXPECT ${SCRIPTDIR}/mount_dropbox.exp $DROPBOX_TOKEN ${DBXFS_CONFIG}
	if [ $? -ne 0 ] ; then
		echo "[ERROR] Failed to mount dropbox, aborting"
		exit 1
	fi

	echo "[INFO] Re-checking if dropbox has been mounted <mountDir=$DROPBOX_MOUNT_DIR> ..."
	if $BIN_MOUNTPOINT -q $DROPBOX_MOUNT_DIR; then
		echo "[INFO] Dropbox has been mounted"
	else
		echo "[ERROR] Dropbox mount failed"
		exit 1
	fi
fi

exit 0
